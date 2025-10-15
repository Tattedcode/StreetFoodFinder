# Street Food Rater - Phase 1 Learning Plan

## What We're Building

A simple app that lets YOU rate street food on YOUR iPhone. Everything saves on your phone only (no internet needed yet). You'll learn SwiftUI basics and MVVM architecture step by step!

## Step-by-Step Build Process

### 1. Set Up Project Structure (MVVM Folders)

**What is MVVM?** It's a way to organize code into 3 parts:

- **Model** = Your data (like "what is a food rating?")
- **View** = What you see on screen (buttons, images, text)
- **ViewModel** = The brain that connects data to what you see

**We'll create:**

- `Models/` folder - holds our data structures
- `ViewModels/` folder - holds the brains of our app  
- `Views/` folder - holds what appears on screen
- `Utilities/` folder - helper tools we might need

### 2. Create the Food Rating Model

**What:** Define what data we save for each food rating
**Includes:**

- Photo of the food
- Photo of the cart (optional)
- Rating (1-10)
- Notes (optional text)
- Location (where the food cart is)
- Date/time when rated

**I'll explain:** What a `struct` is, what `Codable` means, and why we need these

### 3. Create the Main ViewModel

**What:** This is the "brain" that manages all our food ratings
**Does:**

- Keeps track of all ratings
- Adds new ratings
- Deletes ratings
- Saves/loads from phone storage

**I'll explain:** `@Observable`, what arrays are, how saving works

### 4. Build the Main List View

**What:** The first screen you see - shows all your ratings
**Shows:**

- List of all food ratings
- Each item shows: photo thumbnail, rating stars, food cart name
- Button to add new rating

**I'll explain:** `List`, `ForEach`, `NavigationStack`, and how views work

### 5. Build the Add Rating Screen

**What:** Screen where you rate new street food
**Has:**

- Camera button to take food photo
- Camera button to take cart photo (optional)
- Slider to pick rating 1-10
- Text field for notes
- Map to pick location
- Save button

**I'll explain:** `@State`, `TextField`, `Slider`, camera integration, location services

### 6. Build the Detail View

**What:** When you tap a rating, see all the details
**Shows:**

- Full-size photos
- Full rating
- All notes
- Location on small map
- Delete button

**I'll explain:** Navigation, passing data between screens

### 7. Build the Map View

**What:** See all your ratings as pins on a map!
**Shows:**

- Map of your area
- Pin for each food cart you've rated
- Tap pin to see rating details

**I'll explain:** `MapKit`, annotations, coordinates

### 8. Add Local Storage

**What:** Save your ratings so they don't disappear when you close the app
**Uses:** Simple file storage on your iPhone

**I'll explain:** How apps save data locally, `Codable`, file system

### 9. Polish & Test

- Add nice icons and colors
- Make sure everything works smoothly
- Test on iPhone simulator

## Key Concepts You'll Learn

- What SwiftUI is and how it's different from regular code
- MVVM architecture (organizing code properly)
- Property wrappers (`@State`, `@Observable`, `@Binding`)
- Working with camera
- Working with maps and locations
- Saving data locally
- Navigation between screens
- Lists and forms

## What You'll Have at the End

A working app on YOUR phone where you can rate street food, take photos, and see everything on a map - all while understanding exactly how it works!