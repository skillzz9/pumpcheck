from PIL import Image

img = Image.open('UIIdeas/applogo.jpg')
cropped = img.crop((474, 474, 1574, 1574))
cropped = cropped.resize((1024, 1024))
cropped.save('PumpCheck.swiftpm/Assets.xcassets/AppIcon.appiconset/applogo-1024.png')
