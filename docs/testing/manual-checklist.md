# Manual Testing Checklist

## Simulator

- App launches full-screen on iPhone 17 Pro Max simulator.
- Screenshots mode appears by default.
- Settings sheet opens and dismisses.
- Stitch button is disabled before media is selected.

## Device

- App installs on iPhone 17 Pro Max with a personal Apple Developer team.
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
