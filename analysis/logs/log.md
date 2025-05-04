# Weekly/Bi-Weekly Log

## Prompts
Following the [Rose/Bud/Thorn](https://www.panoramaed.com/blog/rose-bud-thorn-activity-and-worksheet#:~:text=%22Rose%2C%20Bud%2C%20Thorn%22%20is%20a%20mindful%20design%2D,day%2C%20week%2C%20or%20month.) model:

### Week 9 - Date: March 14, 2025


### Number of hours: 
10 

### Rose:
Developed the core functionality of the R Shiny app and established basic player interactions with a histogram.


### Bud: 
Shapiro-Wilks test is working but mentor requested a 1-sample T-test instead. 

### Thorn: 
Trouble integrating the physics engine. 


---

### Week 10 - Date: March 21, 2025


### Number of hours: 
10 

### Rose:
We transitioned from the concept-driven interface to a more physics-based experience by implementing Box2DWeb in appi2.R. This marked a major advancement in the game’s feel and realism.


### Bud: 
Still trying to have the game register a 1-sample T-test.

### Thorn: 
Need to come up with an engaging scoring system. 



---

### Week 11 - Date: March 28, 2025


### Number of hours: 
10 

### Rose:
Refined our physics integration and improved UI responsiveness. In appi3.R, we enhanced the rendering logic, brick behavior, and brick removal mechanics using Box2DWeb to make the game more stable and intuitive for users.
Optimized the random histogram generator to create a wider variety of distributions, including clearly non-normal ones like U-shaped and multimodal patterns.

### Bud: 
If possible, move to a different physics engine and platform. One that is even more engaging to the player.

### Thorn: 
Still need to come up with a scoring system. Game still doesn't feel very engaging. Player may not want to play for a long time. Sounds could be added to help with retention.


---

### Week 12 - Date: April 4, 2025



### Number of hours: 
20 

### Rose:
We transitioned the game engine from Box2DWeb to a fully 3D setup using Three.js for graphics and Cannon.js for physics. This brought the histogram to life with realistic perspective and depth. Complete overhaul. Added a way more realistic slingshot mechanic with drag and shoot mechanics rather than the simple button clicks of the previous iteration.

### Bud: 
Still trying to have the game register a 1-sample T-test. Can work on improving the background look.

### Thorn: 
Need to come up with an engaging scoring system. 


---

### Week 13 - Date: April 18, 2025


### Number of hours: 
25 

### Rose:
Created a more structured scoring system, added visual and interactive elements (brick destruction animation), and transitioned fully to using a one-sample t-test to drive the statistical objective. UI now includes a time bar, goal progress bar, and updated in-game stats for score, shots, and p value movement. Visual enhancements include real-time mean line updates, numeric bin labels, and a cleaner game overlay for end-of-round feedback. Hints and feedback messages also help players understand whether their actions are improving or hurting their chance of winning.

### Bud: 
Imrpove background look and feel. Tidy up scoring system loose ends.

### Thorn: 
None.


---

### Week 14 - Date: April 25, 2025


### Number of hours: 
25 

### Rose:
The latest version of the game builds directly off of the previous iteration. We improved the responsiveness and precision of slingshot physics by adjusting gravity, impulse factors, and collision stability settings in the Cannon.js physics engine. Visual updates included cleaning up the reticle, rubber bands, and mean line to ensure sharper, cleaner feedback during gameplay. We also implemented a full visual skybox, creating a more immersive 3D environment around the player. This addition makes the game world feel more complete without distracting from the histogram and gameplay focus.
We tightened up the scoring system so that bonus calculations for time and shot efficiency more accurately reflect player performance, helping players better connect gameplay with statistical movement toward the target p value. Several bug fixes and stability improvements were implemented to avoid glitches when releasing the projectile under edge conditions.
Added sounds as well.

### Bud: 
None.

### Thorn: 
Slight bugs in scoring update and occasional p-value not calculated for certain histograms.

## Additional thought
Overall we made a lot of progress on this game. We made a huge overhaul in the middle of development by switching from Box2D to Three.js. In the end, the scoring can sometimes be off and the p-value occasionally doesn't calculate but it is a fully functional and engaging game.