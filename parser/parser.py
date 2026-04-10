import asyncio
import os
import re

import pandas as pd

from playwright.async_api import async_playwright


async def get_pin_urls(page, scroll_steps):
    pin_urls = []
    for _ in range(scroll_steps):
        await page.evaluate("window.scrollBy(0, window.innerHeight)")
        await asyncio.sleep(2)

        pins = page.locator('[data-grid-item="true"]')
        count = await pins.count()

        for i in range(count):
            pin = pins.nth(i)
            try:
                url = await pin.locator('a').first.get_attribute('href', timeout=3000)
                if url and url.startswith('/'):
                    url = 'https://www.pinterest.com' + url
                    if url not in pin_urls:
                        pin_urls.append(url)
            except Exception as e:
                print(e)
    return pin_urls


async def get_text(locator, timeout=3000, default=None):
    try:
        return await locator.first.inner_text(timeout=timeout)
    except:
        return default


async def get_data_from_post(page):

    title = await get_text(page.locator('[data-test-id="pin-title-wrapper"]'))
    author = await get_text(page.locator('[data-test-id="creator-profile-name"]'))
    save_count = await get_text(page.locator('[data-test-id="reactions-count"]'))
    comment_heading = await get_text(page.locator('#comments-heading'))

    if comment_heading:
            match = re.search(r'(\d+)', comment_heading)
            comment = match.group(1) if match else '0'
    else:
        comment = '0'

    return title, author, save_count, comment


async def download_pins(page, pin_urls, tag_dir):
    results = []
    for i, pin_url in enumerate(pin_urls):
        res = {
            "path": None,
            "url": pin_url,
            "title": None,
            "author": None,
            "save_count": None,
            "comment_count": None,
            "downloaded": False,
            "error": None,
        }
        try:
            await page.goto(pin_url)
            await page.wait_for_load_state("networkidle")
            await asyncio.sleep(1)
            
            res["title"], res["author"], res["save_count"], res["comment_count"] = await get_data_from_post(page)
            
            await page.locator('[data-test-id="closeup-action-bar-button"]').click()
            await asyncio.sleep(1)
            
            async with page.expect_download(timeout=10000) as download_info:
                await page.click('[data-test-id="pin-action-dropdown-download"]')
            
            res["path"] = os.path.join(tag_dir, f"img_{i}.jpg")
            download = await download_info.value
            await download.save_as(res["path"])
            res["downloaded"] = True
        except Exception as e:
            res["error"] = str(e)
        results.append(res)
    return results


def create_pin_records(pin_params, style, tag):
    records = []
    for pin in pin_params:
        records.append({
            "path": pin["path"],
            "url": pin["url"],
            "style": style,
            "tag": tag,
            "title": pin["title"],
            "author": pin["author"],
            "save_count": pin["save_count"],
            "comment_count": pin["comment_count"],
            "downloaded": pin["downloaded"],
            "error": pin["error"],
        })
    return records


async def create_dataset_and_csv(styles, tags, page, data_dir, max_pins, scrolls):
    data = []

    for style in styles:
        for tag in tags:
            query = style + " " + tag
            tag_dir = os.path.join(data_dir, style, tag)

            await page.fill('#searchBoxContainer input', query)
            await page.press('#searchBoxContainer input', 'Enter')

            pin_urls = await get_pin_urls(page, scrolls)
            pin_urls = pin_urls[:max_pins]
            pin_param = await download_pins(page, pin_urls, tag_dir)
            data.extend(create_pin_records(pin_param, style, tag))
    
    df = pd.DataFrame(data)
    csv_path = os.path.join(data_dir, "dataset.csv")
    df.to_csv(csv_path, index=False)


async def scrape_pinterest(state_path, styles, tags, max_pins, scrolls):
    async with async_playwright() as p:
        try:
            data_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
            browser = await p.chromium.launch(
                headless=True,
            )
            context = await browser.new_context(
                storage_state=state_path,
                accept_downloads=True
            )
            page = await context.new_page()

            await page.goto("https://ru.pinterest.com")

            await asyncio.sleep(3)
            
            await create_dataset_and_csv(styles, tags, page, data_dir, max_pins, scrolls)

            await context.close()
            await browser.close()
        except Exception as e:
            print(e)


async def save_auth(state_path):
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False)
        context = await browser.new_context()
        page = await context.new_page()
        await page.goto("https://www.pinterest.com/login/")
        input() 
        await context.storage_state(path=state_path)
        await browser.close()


def main():
    dir_name = os.path.dirname(os.path.abspath(__file__))
    state_path =  os.path.join(dir_name, "state.json")

    if not os.path.exists(state_path):
        asyncio.run(save_auth(state_path))

    styles = [
        "y2k", "old money", "sport",
        "grunge", "office siren", "streetwear",
        "hippy", "country", "gothic",
        "anime", "slavic core", "romantic",
        "retro", "cottage girl", "clean girl",
        "baggy", "basic", "punk",
    ]
    tags = [
        "outfit",
        "accessories",
    ]

    max_pins = 20
    scrolls = 5

    asyncio.run(scrape_pinterest(state_path, styles, tags, max_pins, scrolls))
    

if __name__ == "__main__":
    main()
