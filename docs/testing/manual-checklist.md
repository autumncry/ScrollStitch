# Manual Testing Checklist

## Simulator

- App launches full-screen on iPhone 17 Pro Max simulator.
- Capture tab appears by default with a URL field, web page, and Capture button.
- Default Apple iPhone page loads in the in-app browser.
- Capture scrolls the loaded page and enables Preview, Save, and Share.
- Preview opens a long-image result sheet.
- Imports tab opens the fallback screenshot and recording stitcher.
- Imports settings sheet opens and dismisses.
- Imports Stitch button is disabled before media is selected.

## Device

- App installs on iPhone 17 Pro Max with a personal Apple Developer team.
- A URL can be loaded in the in-app browser.
- Capture completes on a loaded web page and produces a long-image preview.
- Photo permission prompt appears when saving.
- Two or more overlapping screenshots stitch into one long image.
- A short screen recording can be selected from Photos and processed.
- Share sheet exports a PNG.

## Demo Media

Run:

```bash
python3 Scripts/make_demo_media.py
```

Then AirDrop or otherwise copy the generated PNG files to the device Photos library and import them in order.
