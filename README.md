# Robotics Scouting Data Manager

This application is designed to manage robotics competition scouting data, featuring export, import, and real-time save functionalities.

When the app opens, the user is prompted to enter their name (`scoutName`), which is saved in exported files and displayed in the application's header (AppBar).

## Core Functionalities

### 1. Home Page
After logging in, the user is taken to the Home Page, which provides an overview of the current match data and access to other specific scouting pages.

### 2. Match Page
This page is dedicated to entering basic match identifiers and primary scoring data.

#### Input Fields
The following two fields must only allow numerical input (no letters):

* **Team Number:**
    * Included in the exported JSON file as `"teamNumber"`.
    * Included in the HTML file's match overview.
    * The value will be cleared after successful data export.
* **Match Number:**
    * Included in the exported JSON file as `"matchNumber"`.
    * Included in the HTML file's match overview.
    * The value will be cleared after successful data export.

The data from these controllers will be saved as part of the `matchInfo` object in the final export.

#### Scoring
This page includes counters for regular match scoring elements (Assembly Tray, Oven Column, Delivery Hatch).

#### Reset Functionality
A button at the bottom of the page resets the values of all score types to zero (the default value). Scores are automatically reset after data export.

### 3. Endgame Page
This page focuses on tracking high-value endgame scoring elements and penalties.

#### Scoring Rows
This section tracks points scored by distance:

* **Ten Feet Counter (10ft):** Increments **25 points** into `totalEndgameScore`, which is added to the `totalScore`.
* **Fifteen Feet Counter (15ft):** Increments **40 points** into `totalEndgameScore`, which is added to the `totalScore`.
* **Twenty Plus Feet Counter (20+ft):** Increments **40 points** into `totalEndgameScore`, which is added to the `totalScore`.

#### Penalty Tracking
This section tracks various penalties that result in score deduction.

## Menu Functionalities (Top Right Vertical Menu)

The vertical menu expands to offer the following options:

* **Save Match:**
    * Saves the current match data to a defined folder/database structure (e.g., Firestore).
* **Export All Data:**
    * Exports all previous data to a single JSON file downloaded to the user's specified directory.
    * Returns an error if the specified folder (or collection, in a web context) isn't found or accessible.
* **Import All Data:**
    * Opens a file picker allowing the user to select a correctly formatted JSON file.
    * Imports the data from the JSON file into the application's database/storage.
    * Displays an error if the file format is incorrect or necessary information is missing.
* **Log Out:**
    * Clears the `scoutName` variable (sets its value to an empty string), returning the user to the initial login prompt.
    * Data previously entered will remain in the app until manually reset or exported.

## Data and File Format Specifications

### File Name Format (on Export)

Team-teamNum_Match-matchNum__yyyy-MM-DD_hh-mm-SS.json


### Format for Imported JSON Files

The expected structure for both imported and exported JSON data:

```json
{
  "matchInfo": {
    "teamNumber": "teamNum",
    "matchNumber": "matchNum",
    "saveDate": "yyyy-MM-DD_hh-mm-SS",
    "scoutName": "scoutName"
  },
  "scoring": {
    "regular": {
      "assemblyTray": 0,
      "ovenColumn": 0,
      "deliveryHatch": 0,
      "total": 0
    },
    "endgame": {
      "pizza5ft": 0,
      "pizza10ft": 0,
      "pizza15ft": 0,
      "pizza20ft": 0,
      "total": 0
    },
    "penalties": {
      "motorBurn": 0,
      "elevatorMalfunction": 0,
      "mechanismDetached": 0,
      "humanPlayer": 0,
      "robotOutside": 0,
      "totalPointsDeducted": 0
    },
    "finalTotal": 0
  }
}
