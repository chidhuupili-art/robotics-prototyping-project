# roboticsapp11_17_2025
## An app that helps people scout Pizza Panic games
By Ankitha Aravinthan
An app to manage scouting data with:
  - an export function (If a MatchReports folder already exists in the specified directory)
  - an import function (If a correctly formatted json file is selected through the file picker)
  - a save match (Saves a folder with multiple folders nested within, the last folder containing 
    an HTML and JSON file with the data collected through the app)
 When you open the app, you'll be prompted to type your name, which will be displayed in the appBar
 and saved in exported files.
Once logged in, you'll be taken to the Home Page, where if needed, you can manually enter match data.
If that isn't necessary, you could click on the menu items on either side of the Home Page icon, which
take you to pages more specific to the part of the game.
  In the Match Page, there are two TextFieldControllers:
     = Team Number
       - no letters are allowed
       - it will be included in the JSON file exported as "teamNumber" when you click 
         save, or export match.
       - it will be part of the overview in the HTML file exported when you click 
         save, or export match.
       - it will be deleted after the data has been exported
     = Match Number
       - no letters are allowed
       - it will be included in the JSON file exported as "matchNumber" when you click 
         save, or export match.
       - it will be part of the overview in the HTML file exported when you click 
         save, or export match.
       - it will be deleted after the data has been exported
  The data from these controllers will be saved in an array called "matchInfo"
There is also a button at the bottom that resets the values of each score type to zero, the default value.
Again, the scores will automatically be reset after export, so unless there was some severe mishap, that
button shouldn't be used.
Instead, use the decrement buttons.

=== Match Page Description End ===

In the Endgame Page, there are three Scoring Rows:
    =  The Ten Feet Counter
        - increments 25 points into the totalEndgameScore, which is added into the totalScore
    = The Fifteen Feet Counter
        - increments 40 points into the totalEndgameScore, which is added into the totalScore
    =  The Twenty Plus Feet Counter
        - increments 40 points into the totalEndgameScore, which is added into the totalScore 
    
=== Endgame Page Description End ===
  
Other Functionalities
  The vertical menu located in the top right, when clicked, expands into a menu consisting of three options:
      = Save Match
              clicking this button saves match data to a defined folder, which can later be imported using
              the import button
      = Export All Data
              clicking this button exports previous data to the previously defined folder, and returns an error
              the specified folder isn't found in the directory
      = Import All Data
              clicking this button opens a file picker, which allows the user to select any json file in the right
              format, and with the necessary information within it; otherwise, an error is displayed.
      = Log Out
              clicking this button will clear the scoutName variable, or in other words, set its value to an empty
              string; data previously entered will remain in the app, and only clear once exported or manually reset.

