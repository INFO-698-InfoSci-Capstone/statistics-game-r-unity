# Defeat the P: T-Test
A 3D interactive statistical learning game built with R Shiny, Three.js, and Cannon.js where players manipulate histograms through a physics-based slingshot system to understand p-values and t-tests.


[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Overview
"Defeat the P" is an educational game that makes learning about statistical significance engaging and intuitive. Players use a slingshot to launch projectiles at histogram bars, manipulating the data distribution to achieve specific statistical outcomes.

## Key Features

* Interactive 3D Physics Environment: Built with Three.js for rendering and Cannon.js for physics
* Visual Slingshot System: Intuitive drag-and-release mechanics with trajectory prediction
* Real-time Statistical Analysis: Live calculation of p-values and t-test results as the distribution changes
* Educational Visualization: Visual representation of statistical concepts including mean, distribution shapes, and significance levels
* Achievement System: Rewards for efficient strategy and understanding of statistical principles
* Complete Audio System: Sound effects enhance the gameplay experience

## Educational Value
This game helps students understand:

* How changes in data distribution affect p-values
* The relationship between sample mean and statistical significance
* The concept of t-tests and hypothesis testing
* When results are considered statistically significant (p < 0.05)
* How outliers and data points influence statistical outcomes

## Game Objectives
Players are challenged to manipulate the p-value of a t-test in a specific direction:

* p < 0.05: Make the histogram distribution significantly different from the test value
* p ≥ 0.05: Make the histogram distribution similar to the test value

## Scoring System
The scoring system rewards strategic thinking and efficiency:

* +200 points for every 0.01 change in p-value in the right direction
* +2000 points for crossing the significant p=0.05 threshold
* +300-500 points for reaching statistical milestones
* -25 points for each brick hit (encouraging precision)
* Shot penalties that increase with each shot taken

## Achievements

* Sharp Shooter: 1000 points for crossing p=0.05 within 3 shots
* Surgical Strike: 500 points for changing p-value by 0.05+ in 1 shot
* Minimal Impact: 750 points for achieving the goal with ≤5 bricks
* Perfect Execution: 1200 points for goal with ≤3 shots and ≤5 bricks
* Against the Odds: 800 points for achieving goal with extreme initial p-value

## Technologies Used

* R Shiny: Backend framework for statistical calculations
* Three.js: 3D rendering engine
* Cannon.js: Physics engine for realistic object interactions
* JavaScript: Game logic and interactions
* HTML/CSS: UI components and styling

## Key Components

* Dynamic Histogram Generation: Creates varied statistical distributions
* Physics-based Interactions: Projectiles and bricks interact with real physics
* Statistical Integration: R performs t-tests on the fly as distribution changes
* Interactive Slingshot: Drag mechanic with trajectory prediction
* Visual Feedback: Mean line, p-value indicators, and progress tracking

## Installation

1. Clone this repository
2. Ensure R and the following packages are installed: ``` install.packages(c("shiny", "ggplot2", "stats")) ```

3. Run the application: ``` shiny::runApp("path/to/app") ```

Alternatively, you can try the game here (sound not working): https://wetherell.shinyapps.io/Defeat_the_p/ 

## Usage

1. Click "New Game" to start
2. Aim by clicking and dragging the projectile
3. Release to shoot at the histogram bars
4. Observe how your changes affect the p-value
5. Try to achieve the target p-value goal efficiently

## Bugs

* Occasionally, the initial histogram P-value doesn't load. 
* Scoring sometimes adds upon itself excessively.

## Possible Future Enhancements

* Additional statistical tests (ANOVA, Chi-square, etc.)
* More distribution types and challenges
* Multiplayer mode for classroom competitions
* Detailed tutorial system
* Additional visualization options

## Credits

* Game design and implementation: Jonathan McCoy & Varun Jayaram
* Sound effects: (https://freesound.org/) 
* Libraries: Three.js, Cannon.js, R Shiny

This project combines educational content with interactive gameplay to make statistical concepts more accessible and engaging for students at various levels.


        

