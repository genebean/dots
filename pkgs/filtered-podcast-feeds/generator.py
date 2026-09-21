import json
import os
import re
import tempfile
from datetime import date, datetime
from email.utils import parsedate_to_datetime

import requests
from lxml import etree
from lxml import html as lxml_html

CONFIG = os.environ["FEED_CONFIG"]
OUTPUT_DIR = os.environ["OUTPUT_DIR"]
PUBLIC_URL = os.environ["PUBLIC_URL"]


def normalize_text(value):
    if not value:
        return ""

    try:
        fragment = lxml_html.fromstring(f"<div>{value}</div>")
        value = fragment.text_content()
    except Exception:  # noqa: BLE001, S110 - best-effort strip; fall back to raw text
        pass

    return " ".join(value.split())


def element_text(element):
    if element is None:
        return ""

    return normalize_text("".join(element.itertext()))


def get_title(item):
    elements = item.xpath("./*[local-name()='title']")

    if not elements:
        return ""

    return element_text(elements[0])


def get_body(item):
    # Common RSS/Podcast body fields: description, content:encoded,
    # summary, content.
    elements = item.xpath(
        "./*["
        "local-name()='description' or "
        "local-name()='encoded' or "
        "local-name()='summary' or "
        "local-name()='content'"
        "]"
    )

    parts = []

    for element in elements:
        text = element_text(element)

        if text:
            parts.append(text)

    return "\n".join(parts)


def get_episode_date(item):
    elements = item.xpath(
        "./*[local-name()='pubDate' or local-name()='published' or local-name()='date']"
    )

    for element in elements:
        raw = "".join(element.itertext()).strip()

        if not raw:
            continue

        # Standard RSS date
        try:
            return parsedate_to_datetime(raw).date()
        except (TypeError, ValueError):
            pass

        # ISO 8601
        try:
            return datetime.fromisoformat(raw.replace("Z", "+00:00")).date()
        except ValueError:
            pass

        # Bare YYYY-MM-DD
        try:
            return date.fromisoformat(raw)
        except ValueError:
            pass

    return None


def matches_text(haystack, needle, case_sensitive):
    if case_sensitive:
        return needle in haystack

    return needle.casefold() in haystack.casefold()


def item_matches(item, spec):
    filter_text = spec.get("filter")
    search_in = spec.get("searchIn", ["title"])
    case_sensitive = spec.get("caseSensitive", False)

    # Text fields use OR semantics: title OR body OR ...
    if filter_text is not None:
        matches = []

        if "title" in search_in:
            matches.append(matches_text(get_title(item), filter_text, case_sensitive))

        if "body" in search_in:
            matches.append(matches_text(get_body(item), filter_text, case_sensitive))

        if not matches:
            raise RuntimeError(
                "filter specified but searchIn contains no searchable fields"
            )

        if not any(matches):
            return False

    # Date filtering is an additional AND condition.
    since_string = spec.get("since")

    if since_string is not None:
        since = date.fromisoformat(since_string)
        published = get_episode_date(item)

        if published is None:
            return False

        if published < since:
            return False

    return True


def atomic_write(tree, destination):
    fd, temporary = tempfile.mkstemp(dir=OUTPUT_DIR, prefix=".feed-", suffix=".xml")
    os.close(fd)

    try:
        tree.write(
            temporary, encoding="UTF-8", xml_declaration=True, pretty_print=False
        )
        os.chmod(temporary, 0o644)
        os.replace(temporary, destination)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def fetch_source(url, cache):
    if url not in cache:
        response = requests.get(
            url,
            headers={
                "User-Agent": "nixos-filtered-podcast-feeds/1.0",
                "Accept": "application/rss+xml, application/xml, text/xml",
            },
            timeout=(10, 60),
        )
        response.raise_for_status()
        cache[url] = response.content

    return cache[url]


def main():
    with open(CONFIG) as file:
        feeds = json.load(file)

    slug_pattern = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9_-]*$")

    for slug in feeds:
        if not slug_pattern.fullmatch(slug):
            raise RuntimeError(f"Invalid feed name {slug!r}")

    # Avoid downloading the same upstream feed multiple times if several
    # generated feeds use it.
    source_cache = {}

    errors = []
    succeeded = 0

    for slug, spec in feeds.items():
        try:
            xml = fetch_source(spec["source"], source_cache)

            parser = etree.XMLParser(
                remove_blank_text=False, recover=False, resolve_entities=False
            )
            root = etree.fromstring(xml, parser)

            channels = root.xpath("/*[local-name()='rss']/*[local-name()='channel']")

            if len(channels) != 1:
                raise RuntimeError(
                    f"Expected exactly one RSS channel; found {len(channels)}"
                )

            channel = channels[0]
            items = channel.xpath("./*[local-name()='item']")

            if not items:
                raise RuntimeError("Upstream feed contains no items")

            kept = []

            for item in list(items):
                if item_matches(item, spec):
                    kept.append(get_title(item))
                else:
                    channel.remove(item)

            # Preserve an existing good feed rather than replacing it with an
            # empty one after an upstream change.
            if not kept:
                raise RuntimeError(
                    "Filter matched zero episodes; existing output left untouched"
                )

            display_title = spec.get("displayTitle")

            if display_title is not None:
                titles = channel.xpath("./*[local-name()='title']")

                if titles:
                    titles[0].text = display_title

            public_url = f"{PUBLIC_URL}/{slug}.xml"

            # Fix Atom self-reference if one exists.
            for link in channel.xpath("./*[local-name()='link' and @rel='self']"):
                link.set("href", public_url)

            destination = os.path.join(OUTPUT_DIR, f"{slug}.xml")
            atomic_write(etree.ElementTree(root), destination)

            succeeded += 1
            print(f"{slug}: {len(kept)} episodes")

            for title in kept:
                print(f"  {title}")

        except Exception as exc:  # noqa: BLE001 - one bad feed must not abort the others
            message = f"{slug}: {exc}"
            print(f"ERROR: {message}")
            errors.append(message)

    # Process every feed even if one fails. Only report the run as failed
    # when nothing at all succeeded - a single flaky upstream shouldn't
    # page on every refresh when everything else came through.
    if errors and succeeded == 0:
        raise RuntimeError("All feeds failed:\n" + "\n".join(errors))


if __name__ == "__main__":
    main()
