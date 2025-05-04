# 3D Perspective Histogram Game with a Visual Slingshot and Sound System
library(shiny)
library(ggplot2)
library(stats)  # For t.test instead of shapiro.test

ui <- fluidPage(
  tags$head(
    # Load Three.js and Cannon.js libraries
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/cannon.js/0.6.2/cannon.min.js"),
    
    # Custom CSS
    tags$style(HTML("
      body {
        margin: 0;
        padding: 0;
        overflow: auto;
      }
      #gameContainer {
        position: relative;
        width: 100%;
        height: 800px; /* Increased height from 600px to 800px */
      }
      #gameCanvas {
        width: 100%;
        height: 100%;
        display: block;
      }
      #gameUI {
        position: absolute;
        top: 10px;
        left: 10px;
        color: white;
        font-family: Arial, sans-serif;
        text-shadow: 1px 1px 2px black;
        pointer-events: none;
      }
      .control-panel {
        background-color: rgba(255,255,255,0.8);
        border-radius: 8px;
        padding: 15px;
        margin-bottom: 15px;
      }
      .stats-panel {
        background-color: rgba(0,0,0,0.7);
        color: white;
        border-radius: 8px;
        padding: 10px;
      }
      /* Game overlay styling */
      #gameOverlay {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0,0,0,0.8);
        color: white;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        z-index: 10;
        text-align: center;
        font-family: Arial, sans-serif;
        visibility: hidden;
      }
      .overlay-title {
        font-size: 48px;
        margin-bottom: 20px;
        text-shadow: 2px 2px 4px rgba(0,0,0,0.7);
      }
      .overlay-score {
        font-size: 36px;
        margin-bottom: 30px;
      }
      .overlay-message {
        font-size: 24px;
        margin-bottom: 40px;
        max-width: 80%;
      }
      .overlay-button {
        font-size: 18px;
        padding: 12px 24px;
        background-color: #4CAF50;
        border: none;
        border-radius: 5px;
        cursor: pointer;
        color: white;
        transition: background-color 0.3s;
      }
      .overlay-button:hover {
        background-color: #45a049;
      }
      /* Score display styling */
      .score-display {
        font-size: 1.2em;
        font-weight: bold;
        color: #FFD700;
        margin-top: 10px;
        margin-bottom: 10px;
      }
      /* Progress bar styling */
      .progress-section {
        margin-bottom: 15px;
        display: block;
        width: 100%;
        clear: both;
      }
      .progress-label {
        display: block;
        width: 100%;
        margin-bottom: 5px;
        clear: both;
      }
      .progress-container {
        width: 100%;
        background-color: #444;
        border-radius: 5px;
        margin-top: 5px;
        margin-bottom: 5px;
        clear: both;
        display: block;
      }
      .progress-bar {
        height: 20px;
        border-radius: 5px;
        width: 0%;
        transition: width 0.5s;
      }
      .time-bar {
        background-color: #FF9800;
      }
      .goal-bar {
        background-color: #4CAF50;
      }
      /* Sound control styling */
      .sound-button {
        position: absolute;
        top: 10px;
        right: 10px;
        background-color: rgba(0, 0, 0, 0.5);
        color: white;
        border: none;
        border-radius: 4px;
        padding: 8px 12px;
        cursor: pointer;
        font-size: 16px;
        z-index: 100;
      }
      .sound-button:hover {
        background-color: rgba(0, 0, 0, 0.7);
      }
    "))
  ),
  
  # App title and controls
  titlePanel("Defeat the P: T-Test"),
  fluidRow(
    column(3,
           wellPanel(class = "control-panel",
                     actionButton("newGame", "New Game", class = "btn-primary btn-block"),
                     hr(),
                     sliderInput("projectileSize", "Projectile Size:",
                                 min = 0.5, max = 3.0, value = 1.0, step = 0.1),
                     hr(),
                     h4("Game Status:"),
                     div(class = "score-display", "Score: ", textOutput("scoreDisplay", inline = TRUE)),
                     div(class = "score-display", "High Score: ", textOutput("highScoreDisplay", inline = TRUE)),
                     
                     # Updated progress bars with proper structure
                     div(class = "progress-section",
                         p(class = "progress-label", "Time Remaining:"),
                         div(class = "progress-container",
                             div(id = "timeProgressBar", class = "progress-bar time-bar")
                         )
                     ),
                     div(class = "progress-section",
                         p(class = "progress-label", "Goal Progress:"),
                         div(class = "progress-container",
                             div(id = "goalProgressBar", class = "progress-bar goal-bar")
                         )
                     ),
                     
                     hr(),
                     h4("Instructions:"),
                     p("1. Click on the ball and drag backward to aim."),
                     p("2. The reticle shows the predicted landing point."),
                     p("3. Release to shoot the ball towards the histogram."),
                     p("4. Hit bricks to change the shape of the histogram."),
                     p("5. Your goal is to manipulate the p-value in the target direction:"),
                     tags$ul(
                       tags$li("If goal is \"p < 0.05\": Try to make the distribution more different from the test value."),
                       tags$li("If goal is \"p ≥ 0.05\": Try to make the distribution more similar to the test value.")
                     ),
                     
                     hr(),
                     h4("Efficiency-Focused Scoring System:"),
                     p(strong("Main Points:"), " Be strategic and efficient!"),
                     tags$ul(
                       tags$li(tags$span(style="color:#4CAF50", "200 points"), " for every 0.01 change in p-value in the right direction"),
                       tags$li(tags$span(style="color:#FFD700", "2000 points"), " for crossing the significant p=0.05 threshold"),
                       tags$li(tags$span(style="color:#00BCD4", "300-500 points"), " for reaching statistical milestones"),
                       tags$li(tags$span(style="color:#F44336", "-25 points"), " for each brick you hit"),
                       tags$li(tags$span(style="color:#FF9800", "Shot Penalties:"), " Increasing penalty for each shot taken")
                     ),
                     
                     hr(),
                     h4("Achievements:"),
                     tags$ul(
                       tags$li(tags$span(style="color:#FFD700", "Sharp Shooter:"), " 1000 points for crossing p=0.05 within 3 shots"),
                       tags$li(tags$span(style="color:#00BCD4", "Surgical Strike:"), " 500 points for changing p-value by 0.05+ in 1 shot"),
                       tags$li(tags$span(style="color:#9C27B0", "Minimal Impact:"), " 750 points for achieving goal with ≤5 bricks"),
                       tags$li(tags$span(style="color:#4CAF50", "Perfect Execution:"), " 1200 points for goal with ≤3 shots and ≤5 bricks"),
                       tags$li(tags$span(style="color:#FF5722", "Against the Odds:"), " 800 points for achieving goal with extreme initial p-value")
                     ),
                     
                     hr(),
                     h4("Statistical Concepts:"),
                     p("• ", strong("P-value"), ": Measures how likely the results would occur by chance"),
                     p("• ", strong("p < 0.05"), ": Results are statistically significant"),
                     p("• ", strong("p ≥ 0.05"), ": Results are not statistically significant"),
                     p("• ", strong("Mean"), ": The average (shown by the yellow line)"),
                     p("• ", strong("Histogram"), ": Shows the distribution of values"),
                     
                     hr(),
                     div(class = "stats-panel",
                         h4("Stats:"),
                         p("Shots taken: ", textOutput("shotsCount", inline = TRUE)),
                         p("Bricks hit: ", textOutput("bricksHitCount", inline = TRUE)),
                         hr(),
                         h4("T-Test Stats:"),
                         p("Initial mean: ", textOutput("initialMean", inline = TRUE)),
                         p("Target p-value: ", textOutput("targetPValue", inline = TRUE)),
                         p("Current p-value: ", textOutput("currentPValue", inline = TRUE),
                           textOutput("goalStatus", inline = TRUE)),
                         hr(),
                         h4("T-Test Results:"),
                         p("Test value: ", textOutput("testValue", inline = TRUE)),
                         p("Current mean: ", textOutput("currentMean", inline = TRUE)),
                         p("Interpretation: ", textOutput("interpretation", inline = TRUE))
                     )
           )
    ),
    
    # Game canvas
    column(9,
           div(id = "gameContainer",
               # Game over overlay
               div(id = "gameOverlay",
                   div(id = "overlayTitle", class = "overlay-title", "Game Over"),
                   div(id = "overlayMessage", class = "overlay-message", "Message goes here"),
                   actionButton(inputId = "overlayButton", label = "Play Again", class = "overlay-button")
               ),
               
               # Add sound toggle button
               tags$button(id = "soundToggle", class = "sound-button", "🔊"),
               
               div(id = "gameUI"),
               tags$canvas(id = "gameCanvas")
           )
    )
  ),
  
  # JavaScript for the game
  tags$script(HTML('
    $(document).ready(function() {
      // === Global Variables ===
      let scene, camera, renderer, world;
      let shotsCount = 0;
      let bricksHitCount = 0;
      let initialHistogram = [];
      let initialPValue = null;
      let currentPValue = null;
      let targetPValue = null;
      let pValueUpdateInProgress = false;
      
      // NEW: Starting potential score and tracking variables
      let potentialMaxScore = 10000; // Start with 10,000 potential points
      let score = 0;
      let highScore = 0;
      let gameActive = false;
      let gameTimer = null;
      let timeRemaining = 90; // 90 seconds
      let maxTime = 90;
      let goalAchieved = false;
      
      // Track achievements
      const achievements = {
        sharpShooter: false,       // Cross p=0.05 within 3 shots
        surgicalStrike: false,     // Change p-value by at least 0.05 with a single shot
        minimalImpact: false,      // Achieve goal by hitting 5 or fewer bricks
        perfectExecution: false,   // Complete goal with ≤3 shots and ≤5 bricks
        againstTheOdds: false      // Achieve goal with extreme initial p-value
      };
      
      // Track achievements progress
      let bricksHitThisGame = 0;
      let largestPValueChange = 0;
      
      // New visualization variables
      let meanLine = null;
      let valueLabels = [];
      let currentMean = null;
      
      // Brick settings
      const FLOOR_SIZE = 100;
      const BRICK_DEPTH = 2;
      const BRICK_SPACING = 0.2;
      const BRICK_WIDTH = 4;
      const BRICK_HEIGHT = 2;
      let gameBrickColor = 0x0095DD; // Default initial color (blue)
    const colorOptions = [0xFF5733, 0x33FF57, 0x3357FF, 0xF3FF33, 0xFF33F3, 0x33FFF3, 0xFF3F33, 0x3FFF33, 0x333FFF]; // Colors to choose from
      
      // Slingshot settings
      let projectileSize = 1.0;
      const powerMultiplier = 1000; // Fixed power value of 1000
      const gravityStrength = -9.8; // Added gravity for more realistic projectile motion
      
      // Drag and impulse conversion factors
      const dragFactor = 0.005;     // Reduced for more precise control
      const impulseFactor = 200;    // Adjusted for better feel with gravity
      
      // Game objects arrays
      let projectiles = [];
      let bricks = [];
      let histogram = [];
      
      // Slingshot drag variables
      let dragging = false;
      let initialMouse = { x: 0, y: 0 };
      let initialBallPos = new THREE.Vector3(); // Resting position of ball
      let dragOffset = new THREE.Vector3(); // Stores the offset from rest position for trajectory calculations
      
      // Slingshot components
      let shooter;       // Visual reference for ball starting position (pouch)
      let ball;          // The ball mesh (will be draggable)
      let ballBody;      // Cannon.js physics body for the ball (set on release)
      let leftPost, rightPost;  // Slingshot posts
      let bandLeft, bandRight;  // Lines representing rubber bands
      let reticle;       // Visual landing point prediction
      let trajectoryLine; // Line showing the predicted trajectory
      
      // DOM elements
      const container = document.getElementById("gameContainer");
      const canvas = document.getElementById("gameCanvas");
      const gameUI = document.getElementById("gameUI");
      const gameOverlay = document.getElementById("gameOverlay");
      const overlayTitle = document.getElementById("overlayTitle");
      const overlayMessage = document.getElementById("overlayMessage");
      const overlayButton = document.getElementById("overlayButton");
      const timeProgressBar = document.getElementById("timeProgressBar");
      const goalProgressBar = document.getElementById("goalProgressBar");
      const soundToggle = document.getElementById("soundToggle");
      
      // === Sound System Setup ===
      function setupSoundSystem() {
        // Sound storage
        const sounds = {};
        
        // Sound files mapping
        const soundFiles = {
          slingshot: "slingshot.mp3",
          brickHit: "brick_hit.flac",
          victory: "victory.flac",
          gameOver: "game_over.wav",
          click: "click.wav",
          countdown: "countdown.wav",
          levelUp: "level_up.wav",
          penalty: "penalty.wav"
        };
        
        // Create audio elements for each sound
        Object.keys(soundFiles).forEach(name => {
          const audio = new Audio(`/${soundFiles[name]}`);
          console.log(`Loading sound: ${name} from /${soundFiles[name]}`);
          sounds[name] = audio;
        });
        
        // Play a sound function
        function playSound(name, options = {}) {
          console.log(`Attempting to play sound: ${name}`);
          
          if (!sounds[name]) {
            console.warn(`Sound ${name} not loaded`);
            return null;
          }
          
          // Clone the audio element for overlapping sounds
          const audioToPlay = sounds[name].cloneNode();
          
          // Set volume
          audioToPlay.volume = options.volume || 1.0;
          
          // Set playback rate if specified
          if (options.rate) {
            audioToPlay.playbackRate = options.rate;
          }
          
          // Play the sound
          const playPromise = audioToPlay.play();
          
          // Handle play promise to catch any errors
          if (playPromise !== undefined) {
            playPromise.catch(error => {
              console.warn(`Error playing sound ${name}:`, error);
            });
          }
          
          // For looping sounds, return control object
          if (options.loop) {
            audioToPlay.loop = true;
            return {
              stop: function() {
                audioToPlay.pause();
                audioToPlay.currentTime = 0;
              }
            };
          }
          
          return null;
        }
        
        // Mute functionality
        let muted = false;
        
        function toggleMute() {
          muted = !muted;
          // Set all audio elements to muted state
          Object.values(sounds).forEach(audio => {
            audio.muted = muted;
          });
          return muted;
        }
        
        // Return the sound API
        return {
          play: function(name, options = {}) {
            if (!muted) {
              return playSound(name, options);
            }
            return null;
          },
          toggleMute: toggleMute,
          isMuted: function() { return muted; }
        };
      }
      
      // Initialize the sound system
      const soundSystem = setupSoundSystem();
      
      // Add sound toggle button functionality
      soundToggle.addEventListener("click", function() {
        const muted = soundSystem.toggleMute();
        soundToggle.textContent = muted ? "🔇" : "🔊";
        
        // Play click sound if unmuting
        if (!muted) {
          soundSystem.play("click", { volume: 0.5 });
        }
      });
      
      Shiny.addCustomMessageHandler("updateInitialPValue", function(pValue) {
        initialPValue = pValue;
        currentPValue = pValue;
        targetPValue = (pValue >= 0.05) ? "p < 0.05" : "p ≥ 0.05";
        Shiny.setInputValue("targetPValueType", targetPValue);
        updateGoalProgressBar();
        
        // Check if this is an "against the odds" scenario
        checkAgainstTheOddsCondition(pValue);
        
        console.log("Initial p-value set to: " + pValue);
        console.log("Target p-value type set to: " + targetPValue);
      });
      
      // NEW: Check for Against The Odds achievement condition
      function checkAgainstTheOddsCondition(pValue) {
        // Consider it "against the odds" if initial p-value is very far from threshold
        if (pValue <= 0.01 || pValue >= 0.3) {
          console.log("Against the odds scenario detected with p-value: " + pValue);
          showAchievementPopup("Against The Odds Challenge!");
        }
      }
      
      Shiny.addCustomMessageHandler("updateCurrentPValue", function(pValue) {
        const previousPValue = currentPValue;
        currentPValue = pValue;
        updateGoalProgressBar();
        
        // Track largest p-value change for Surgical Strike achievement
        const change = Math.abs(pValue - previousPValue);
        if (change > largestPValueChange) {
          largestPValueChange = change;
          
          // Check for Surgical Strike achievement (0.05+ change in single shot)
          if (change >= 0.05 && !achievements.surgicalStrike) {
            achievements.surgicalStrike = true;
            updateScore(500);
            soundSystem.play("levelUp", { volume: 0.7 });
            showAchievementPopup("Surgical Strike! +500");
          }
        }
        
        checkWinCondition();
        console.log("Current p-value updated to: " + pValue);
      });
      
      Shiny.addCustomMessageHandler("updateCurrentMean", function(mean) {
        currentMean = mean;
        console.log("Received mean update:", mean);
        // Update the mean line if it exists
        if (meanLine && scene.children.includes(meanLine)) {
          updateMeanLine();
        }
      });
      
      Shiny.addCustomMessageHandler("updateProjectileSize", function(size) {
        console.log("Updating projectile size to: " + size);
        projectileSize = size;
        
        // Update the existing ball object
        if (ball) {
          scene.remove(ball);
          const ballGeometry = new THREE.SphereGeometry(projectileSize, 16, 16);
          const ballMaterial = new THREE.MeshStandardMaterial({ color: 0x0095DD, metalness: 0.3, roughness: 0.6 });
          ball = new THREE.Mesh(ballGeometry, ballMaterial);
          ball.position.copy(initialBallPos);
          ball.castShadow = true;
          scene.add(ball);
          updateBands();
        }
      });
      
      // === Updated Efficiency-Focused Scoring System Functions ===
      function resetScoring() {
        // Reset score variables
        potentialMaxScore = 10000;
        score = 0;
        bricksHitThisGame = 0;
        largestPValueChange = 0;
        
        // Reset achievements for new game
        Object.keys(achievements).forEach(key => {
          achievements[key] = false;
        });
        
        // Update UI
        Shiny.setInputValue("score", score);
        Shiny.setInputValue("bricksHit", bricksHitThisGame);
      }
      
      function updateScore(points) {
        // Add points
        score += points;
        
        // Cannot go below 0
        score = Math.max(0, score);
        
        // Update Shiny with score
        Shiny.setInputValue("score", score);
        
        // Update high score if needed
        if (score > highScore) {
          highScore = score;
          Shiny.setInputValue("highScore", highScore);
        }
        
        // Visual feedback for score change
        if (points > 0) {
          showScorePopup(points);
        } else if (points < 0) {
          showPenaltyPopup(points);
        }
      }
      
      // NEW: Calculate the shot penalty based on exponential increase
      function calculateShotPenalty(shotNumber) {
        if (shotNumber <= 1) return 0; // No penalty for first shot
        
        // Exponential penalties for subsequent shots
        switch(shotNumber) {
          case 2: return -100;
          case 3: return -300;
          case 4: return -600;
          case 5: return -1000;
          default: return -1500; // Each additional shot
        }
      }
      
      function showScorePopup(points) {
        // Create a div for the score popup
        const popup = document.createElement("div");
        
        const pointsText = `+${points}`;
        
        popup.textContent = pointsText;
        popup.style.position = "absolute";
        popup.style.color = points >= 1000 ? "#FFD700" : points >= 500 ? "#00FFFF" : "#FFFFFF";
        popup.style.fontSize = points >= 1000 ? "32px" : points >= 500 ? "28px" : "24px";
        popup.style.fontWeight = "bold";
        popup.style.textShadow = "2px 2px 4px rgba(0,0,0,0.7)";
        popup.style.zIndex = "1000";
        popup.style.opacity = "1";
        popup.style.transition = "opacity 1s, transform 1s";
         
        // Position near last hit
        const randomOffset = Math.floor(Math.random() * 100) - 50;
        popup.style.left = `${canvas.offsetWidth / 2 + randomOffset}px`;
        popup.style.top = `${canvas.offsetHeight / 2 - 100}px`;
         
        document.getElementById("gameContainer").appendChild(popup);
         
        // Animate and remove
        setTimeout(() => {
          popup.style.opacity = "0";
          popup.style.transform = "translateY(-50px)";
          setTimeout(() => {
            popup.remove();
          }, 1000);
        }, 100);
      }
      
      function showPenaltyPopup(points) {
        // Create a div for the penalty popup
        const popup = document.createElement("div");
        
        popup.textContent = points;
        popup.style.position = "absolute";
        popup.style.color = "#FF4136"; // Red for penalties
        popup.style.fontSize = "24px";
        popup.style.fontWeight = "bold";
        popup.style.textShadow = "2px 2px 4px rgba(0,0,0,0.7)";
        popup.style.zIndex = "1000";
        popup.style.opacity = "1";
        popup.style.transition = "opacity 1s, transform 1s";
         
        // Position near last hit but lower
        const randomOffset = Math.floor(Math.random() * 100) - 50;
        popup.style.left = `${canvas.offsetWidth / 2 + randomOffset}px`;
        popup.style.top = `${canvas.offsetHeight / 2 - 50}px`;
         
        document.getElementById("gameContainer").appendChild(popup);
        
        // Play penalty sound
        soundSystem.play("penalty", { volume: 0.4 });
         
        // Animate and remove
        setTimeout(() => {
          popup.style.opacity = "0";
          popup.style.transform = "translateY(50px)";
          setTimeout(() => {
            popup.remove();
          }, 1000);
        }, 100);
      }
      
      function showAchievementPopup(message) {
        const popup = document.createElement("div");
        popup.textContent = message;
        
        // Style the popup
        popup.style.position = "absolute";
        popup.style.right = "20px";
        popup.style.top = "150px";
        popup.style.backgroundColor = "rgba(255, 215, 0, 0.8)";
        popup.style.color = "#000";
        popup.style.padding = "10px 15px";
        popup.style.borderRadius = "5px";
        popup.style.fontSize = "16px";
        popup.style.fontWeight = "bold";
        popup.style.zIndex = "1000";
        popup.style.opacity = "1";
        popup.style.transition = "opacity 1.5s";
        popup.style.maxWidth = "250px";
        popup.style.textAlign = "center";
        
        document.getElementById("gameContainer").appendChild(popup);
        
        // Animate and remove
        setTimeout(() => {
          popup.style.opacity = "0";
          setTimeout(() => {
            popup.remove();
          }, 1500);
        }, 3000);
      }
      
      // NEW: Apply a brick hit penalty
      function applyBrickHitPenalty() {
        const penalty = -25; // -25 points per brick
        updateScore(penalty);
        bricksHitThisGame++;
        Shiny.setInputValue("bricksHit", bricksHitThisGame);
      }
      
      function calculatePValueMovementPoints(previousPValue, newPValue, targetDirection) {
        if (previousPValue === null || newPValue === null) return 0;
        
        // Calculate the movement (absolute difference)
        const movement = Math.abs(newPValue - previousPValue);
        const significantThreshold = 0.05;
        
        // Check if were moving in the desired direction
                   let movingCorrectDirection = false;
                   if (targetDirection.includes("< 0.05") && newPValue < previousPValue) {
                     movingCorrectDirection = true;
                   } else if (targetDirection.includes("≥ 0.05") && newPValue > previousPValue) {
                     movingCorrectDirection = true;
                   }
                   
                   // If not moving in the correct direction, no points
                   if (!movingCorrectDirection) return 0;
                   
                   // INCREASED points for p-value movement - 200 points per 0.01 change
                   const movementPoints = Math.round(movement * 20000);
                   
                   // Show explanation of p-value change
                   showPValueChangeExplanation(previousPValue, newPValue, targetDirection);
                   
                   // Bonus for crossing the significance threshold
                   let significanceBonus = 0;
                   
                   // Check if we crossed the significance threshold
                   const crossedThreshold = (previousPValue >= significantThreshold && newPValue < significantThreshold) || 
                     (previousPValue < significantThreshold && newPValue >= significantThreshold);
                   
                   if (crossedThreshold) {
                     significanceBonus = 2000; // Increased bonus for crossing threshold
                     
                     // Check for Sharp Shooter achievement (threshold crossed within 3 shots)
                     if (shotsCount <= 3 && !achievements.sharpShooter) {
                       achievements.sharpShooter = true;
                       significanceBonus += 1000;
                       showAchievementPopup("Sharp Shooter! +1000");
                     }
                     
                     // Play achievement sound
                     soundSystem.play("levelUp", { volume: 0.8 });
                     
                     // Show special visual effect
                     createVictoryCelebration();
                     
                     // Show goal achievement message
                     showGoalAchievementMessage();
                   }
                   
                   // Return total points from movement plus any bonus
                   return movementPoints + significanceBonus;
                   }

function checkStatisticalMilestones(pValue, previousPValue) {
  if (previousPValue === null || pValue === null) return 0;
  
  // Statistical significance milestones
  const milestones = [
    { threshold: 0.001, points: 500, message: "Highly Significant! (p < 0.001)" },
    { threshold: 0.01, points: 400, message: "Very Significant! (p < 0.01)" },
    { threshold: 0.05, points: 300, message: "Significant! (p < 0.05)" },
    { threshold: 0.1, points: 200, message: "Marginally Significant! (p < 0.1)" }
  ];
  // Check if weve crossed any milestones in either direction
        for (const milestone of milestones) {
          // Moving from above threshold to below (becoming more significant)
          if (previousPValue >= milestone.threshold && pValue < milestone.threshold) {
            // Only award points if this is the target direction
            if (targetPValue.includes("< 0.05")) {
              showAchievementPopup(milestone.message + ` +${milestone.points}`);
              soundSystem.play("levelUp", { volume: 0.6 });
              return milestone.points;
            }
          }
          // Moving from below threshold to above (becoming less significant)
          else if (previousPValue < milestone.threshold && pValue >= milestone.threshold) {
            // Only award points if this is the target direction
            if (targetPValue.includes("≥ 0.05")) {
              showAchievementPopup(milestone.message + ` +${milestone.points}`);
              soundSystem.play("levelUp", { volume: 0.6 });
              return milestone.points;
            }
          }
        }
        
        return 0;
      }
      
      function calculateGameEndBonus() {
        // Time bonus - kept from original
        const timeBonus = Math.round(timeRemaining * 5);
        
        // Achievement bonuses
        let achievementBonus = 0;
        
        // Check for achievements not yet awarded
        if (bricksHitThisGame <= 5 && !achievements.minimalImpact) {
          achievements.minimalImpact = true;
          achievementBonus += 750;
          showAchievementPopup("Minimal Impact! +750");
        }
        
        // Check for Perfect Execution (≤3 shots and ≤5 bricks)
        if (shotsCount <= 3 && bricksHitThisGame <= 5 && !achievements.perfectExecution) {
          achievements.perfectExecution = true;
          achievementBonus += 1200;
          showAchievementPopup("Perfect Execution! +1200");
        }
        
        // Check for Against The Odds (extreme initial p-value)
        if ((initialPValue <= 0.01 || initialPValue >= 0.3) && !achievements.againstTheOdds) {
          achievements.againstTheOdds = true;
          achievementBonus += 800;
          showAchievementPopup("Against The Odds! +800");
        }
        
        // Calculate remaining potential score
        const potentialScore = Math.max(0, potentialMaxScore - 
          (shotsCount <= 1 ? 0 : calculateShotPenalty(shotsCount) * -1));
        
        // Sum of all bonuses
        const totalBonus = timeBonus + achievementBonus + potentialScore;
        
        return {
          timeBonus: timeBonus,
          achievementBonus: achievementBonus,
          potentialScore: potentialScore,
          total: totalBonus
        };
      }
      
      function startGameTimer() {
        if (gameTimer) {
          clearInterval(gameTimer);
        }
        
        timeRemaining = maxTime;
        updateTimeProgressBar();
        
        gameTimer = setInterval(function() {
          // Slow down time depletion to reduce pressure
          timeRemaining -= 0.8; // Only decrease by 0.8 seconds per second
          updateTimeProgressBar();
          
          if (timeRemaining <= 0) {
            clearInterval(gameTimer);
            endGame(false, "Times up! But dont worry - take your time to understand how the histogram and p-value are related.");
          }
        }, 1000);
      }
      
      // Countdown sound variables
      let countdownSound = null;
      
      function updateTimeProgressBar() {
        const percentage = (timeRemaining / maxTime) * 100;
        timeProgressBar.style.width = percentage + "%";
        
        // Change color based on time remaining
        if (percentage < 15) {
          timeProgressBar.style.backgroundColor = "#F44336"; // Red when very low on time
        } else if (percentage < 30) {
          timeProgressBar.style.backgroundColor = "#FF9800"; // Orange when low on time
        } else {
          timeProgressBar.style.backgroundColor = "#4CAF50"; // Green when plenty of time
        }
        
        // Play countdown sound only for last 5 seconds
        if (timeRemaining <= 5 && timeRemaining > 0 && !countdownSound) {
          countdownSound = soundSystem.play("countdown", { volume: 0.3, loop: true });
        } else if ((timeRemaining > 5 || timeRemaining <= 0) && countdownSound) {
          if (countdownSound && countdownSound.stop) {
            countdownSound.stop();
          }
          countdownSound = null;
        }
      }
      
      // Modified handleCollisions function to apply brick hit penalties
      function handleCollisions() {
        // Create an array to store which projectiles have hit something this frame
        const projectileHits = {};
        
        projectiles.forEach(projectile => {
          if (!projectile) return;
          
          // Initialize hits counter for this projectile if not already done
          if (!projectileHits[projectile.id]) {
            projectileHits[projectile.id] = 0;
          }
          
          const projPos = projectile.mesh.position;
          const projRadius = projectile.mesh.geometry.parameters.radius;
          
          // Check for collisions with each brick
          bricks.forEach(brick => {
            if (brick.isRemoved) return;
            const brickPos = brick.mesh.position;
            const dx = Math.abs(projPos.x - brickPos.x);
            const dy = Math.abs(projPos.y - brickPos.y);
            const dz = Math.abs(projPos.z - brickPos.z);
            
            if (dx < BRICK_WIDTH/2 + projRadius &&
                dy < BRICK_HEIGHT/2 + projRadius &&
                dz < BRICK_DEPTH/2 + projRadius) {
              
              console.log("Hit brick at bin " + brick.binIndex + ", level " + brick.level);
              
              // Count this hit for the projectile
              projectileHits[projectile.id]++;
              
              // Apply brick hit penalty
              applyBrickHitPenalty();
              
              // Play hit sound with pitch based on height
              const baseRate = 1.0;
              const levelInfluence = 0.05; // 5% change per level
              const rate = baseRate - (brick.level * levelInfluence);
              
              soundSystem.play("brickHit", {
                volume: 0.6,
                rate: rate
              });
              
              // Create visual hit effect
              createHitEffect(brick.mesh.position);
              
              // Store the bin index before removing
              const hitBinIndex = brick.binIndex;
              
              // Mark brick as removed
              brick.isRemoved = true;
              scene.remove(brick.mesh);
              world.remove(brick.body);
              
              // Use setTimeout to let the physics engine update before we rearrange bricks
              setTimeout(() => {
                // Rearrange all bricks in this bin
                rearrangeBricksInBin(hitBinIndex);
                
                // Update the histogram after rearranging
                setTimeout(updateHistogramData, 500);
              }, 100);
            }
          });
        });
      }
      
      // Modified function to update histogram data with p-value focus
      function updateHistogramData() {
        // If an update is already in progress, dont start another one
  if (pValueUpdateInProgress) {
    console.log("P-value update already in progress, skipping duplicate call");
    return;
  }
  
  // Set flag to indicate update is in progress
  pValueUpdateInProgress = true;
  
  // Store current p-value for comparison
  const previousPValue = currentPValue;
  
  // Initialize counts to 0 for all bins
  let newCounts = Array(histogram.length).fill(0);
  
  // Group bricks by bin based on current X position
  bricks.forEach(brick => {
    if (!brick.isRemoved) {
      // Find which bin this brick currently belongs to based on its X position
      const binWidth = BRICK_WIDTH + BRICK_SPACING;
      const totalWidth = histogram.length * binWidth;
      const startX = -totalWidth / 2 + binWidth / 2;
      
      // Calculate which bin index this brick is now in
      const relativeX = brick.mesh.position.x - startX;
      const currentBinIndex = Math.round(relativeX / binWidth);
      
      // Only count if its in a valid bin
            if (currentBinIndex >= 0 && currentBinIndex < histogram.length) {
              newCounts[currentBinIndex]++;
              
              // Update the bricks bin index to reflect its current position
      brick.binIndex = currentBinIndex;
    }
  }
});
  
  // Update the histogram data
  for (let i = 0; i < histogram.length; i++) {
    histogram[i].count = newCounts[i];
  }
  
  // Send updated data to R
  Shiny.setInputValue("histogramData", newCounts);
  
  // Reassign level values based on current heights within bins
  reorganizeBrickLevels();
  
  // Update the mean line after histogram changes
  if (meanLine) {
    updateMeanLine();
  }
  
  // Update the goal progress bar
  updateGoalProgressBar();
  
  // Calculate and award points based on p-value changes
  // This happens after R has processed the new histogram data and sent back the new p-value
  setTimeout(() => {
    if (previousPValue !== null && currentPValue !== null && previousPValue !== currentPValue) {
      // Award points for p-value movement - this is now the MAIN source of points
      const movementPoints = calculatePValueMovementPoints(previousPValue, currentPValue, targetPValue);
      if (movementPoints > 0) {
        updateScore(movementPoints);
      }
      
      // Check if weve crossed any statistical significance milestones
            const milestonePoints = checkStatisticalMilestones(currentPValue, previousPValue);
            if (milestonePoints > 0) {
              updateScore(milestonePoints);
            }
          }
          
          // Clear the flag to allow future updates
          pValueUpdateInProgress = false;
          console.log("P-value update complete, ready for next update");
        }, 500); // Wait for R to process the data and update currentPValue
      }
      
      // Function to show an initial message explaining the goal
      function showGoalMessage() {
        // Wait until we have the target p-value
        setTimeout(() => {
          if (!targetPValue) return;
          
          const message = document.createElement("div");
          let goalText = "";
          
          if (targetPValue.includes("< 0.05")) {
            goalText = "Make the p-value DECREASE below 0.05";
          } else {
            goalText = "Make the p-value INCREASE above 0.05";
          }
          
          message.innerHTML = `<strong>GOAL:</strong><br>${goalText}<br><br><strong>BE EFFICIENT!</strong><br>
          Every shot and every brick hit costs points.`;
          
          // Modified styling to make it appear on the right side
          message.style.position = "absolute";
          message.style.right = "20px"; 
          message.style.top = "100px"; 
          message.style.transform = "none"; 
          message.style.color = "#FFFFFF";
          message.style.backgroundColor = "rgba(0, 0, 0, 0.8)";
          message.style.padding = "10px 15px";
          message.style.borderRadius = "8px";
          message.style.fontSize = "16px"; 
          message.style.fontWeight = "normal";
          message.style.zIndex = "1000";
          message.style.opacity = "1";
          message.style.transition = "opacity 0.5s, transform 0.5s";
          message.style.textAlign = "center";
          message.style.maxWidth = "250px"; 
          message.style.border = "2px solid #FFD700";
          message.style.boxShadow = "0 0 10px rgba(0,0,0,0.5)";
          
          document.getElementById("gameContainer").appendChild(message);
          
          // Play info sound
          soundSystem.play("click", { volume: 0.5 });
          
          // Animate and remove
          setTimeout(() => {
            message.style.opacity = "0";
            message.style.transform = "translateX(50px)"; // Slide out to the right
            setTimeout(() => {
              message.remove();
            }, 500);
          }, 8000); // Show for 8 seconds (increased from 6)
        }, 1000);
      }
      
      // Enhanced goal achievement popup for educational value
      function showGoalAchievementMessage() {
        if (!targetPValue || !currentPValue) return;
        
        const message = document.createElement("div");
        let explanationText = "";
        
        if (targetPValue.includes("< 0.05") && currentPValue < 0.05) {
          explanationText = `Youve made the p-value significant (${currentPValue.toFixed(4)} < 0.05)!`;
    } else if (targetPValue.includes("≥ 0.05") && currentPValue >= 0.05) {
      explanationText = `Youve made the p-value non-significant (${currentPValue.toFixed(4)} ≥ 0.05)!`;
    }
    
    message.innerHTML = `<strong>GOAL ACHIEVED!</strong><br>${explanationText}`;
    
    // Style similarly to the initial goal message but with success colors
    message.style.position = "absolute";
    message.style.right = "20px";
    message.style.top = "100px"; 
    message.style.transform = "none";
    message.style.color = "#FFFFFF";
    message.style.backgroundColor = "rgba(0, 100, 0, 0.9)";
    message.style.padding = "10px 15px";
    message.style.borderRadius = "10px";
    message.style.fontSize = "16px";
    message.style.fontWeight = "bold";
    message.style.zIndex = "1000";
    message.style.opacity = "1";
    message.style.transition = "opacity 1s, transform 1s";
    message.style.textAlign = "center";
    message.style.maxWidth = "200px";
    message.style.border = "3px solid #FFD700";
    message.style.boxShadow = "0 0 20px rgba(255, 215, 0, 0.7)";
    
    document.getElementById("gameContainer").appendChild(message);
    
    // Animate and remove after a longer display period
    setTimeout(() => {
      message.style.opacity = "0";
      message.style.transform = "translateX(50px)"; // Slide out to the right
      setTimeout(() => {
        message.remove();
      }, 1000);
    }, 5000); // Show for 5 seconds
  }
  
  // Function to explain p-value changes
  function showPValueChangeExplanation(previousPValue, newPValue, targetDirection) {
    if (previousPValue === null || newPValue === null) return;
    
    // Only show for significant changes
    if (Math.abs(newPValue - previousPValue) < 0.01) return;
    
    const message = document.createElement("div");
    const direction = newPValue < previousPValue ? "decreased" : "increased";
    const goodChange = (targetDirection.includes("< 0.05") && newPValue < previousPValue) || 
      (targetDirection.includes("≥ 0.05") && newPValue > previousPValue);
    
    const changeAmount = Math.abs(newPValue - previousPValue).toFixed(4);
    
    message.innerHTML = `P-value ${direction}<br>by ${changeAmount}<br>
      <span style="color:${goodChange ? "#4CAF50" : "#F44336"}">
      ${goodChange ? "Good!" : "Wrong direction!"}</span>`;
      
      // Position below the goal message
      message.style.position = "absolute";
      message.style.right = "20px";
      message.style.top = "220px"; // Below the goal message
      message.style.backgroundColor = "rgba(0, 0, 0, 0.7)";
      message.style.color = "#FFFFFF";
      message.style.padding = "8px 12px";
      message.style.borderRadius = "5px";
      message.style.fontSize = "14px";
      message.style.fontWeight = "bold";
      message.style.zIndex = "1000";
      message.style.opacity = "1";
      message.style.transition = "opacity 1.5s";
      message.style.maxWidth = "150px";
      message.style.textAlign = "center";
      
      document.getElementById("gameContainer").appendChild(message);
      
      // Animate and remove
      setTimeout(() => {
        message.style.opacity = "0";
        setTimeout(() => {
          message.remove();
        }, 1500);
      }, 3000);
  }
  
  // Function to provide hints if player is struggling
  function showHint() {
    if (!targetPValue || !currentPValue) return;
    
    // Only show hints if player has taken several shots without making progress
    if (shotsCount < 3) return;
    
    const message = document.createElement("div");
    let hintText = "";
    
    if (targetPValue.includes("< 0.05")) {
      hintText = "Hint: Try to make the distribution more asymmetrical by selectively removing key bricks. Be efficient!";
    } else {
      hintText = "Hint: Try to make the distribution more symmetrical by carefully removing specific bricks. Be strategic!";
    }
    
    message.textContent = hintText;
    
    // Modified styling to position on the left side
    message.style.position = "absolute";
    message.style.left = "20px"; // Position from left side
    message.style.top = "300px"; // Position near top-left
    message.style.transform = "none"; // Remove any transformation
    message.style.backgroundColor = "rgba(25, 118, 210, 0.8)";
    message.style.color = "white";
    message.style.padding = "8px 12px";
    message.style.borderRadius = "5px";
    message.style.fontSize = "14px";
    message.style.maxWidth = "200px";
    message.style.textAlign = "left";
    message.style.zIndex = "1000";
    message.style.opacity = "0";
    message.style.transition = "opacity 1s";
    message.style.border = "1px solid rgba(255,255,255,0.3)";
    message.style.boxShadow = "0 2px 5px rgba(0,0,0,0.2)";
    
    document.getElementById("gameContainer").appendChild(message);
    
    // Add a small hint icon
    const hintIcon = document.createElement("div");
    hintIcon.textContent = "💡";
    hintIcon.style.position = "absolute";
    hintIcon.style.left = "-20px";
    hintIcon.style.top = "0";
    hintIcon.style.fontSize = "16px";
    message.appendChild(hintIcon);
    
    // Fade in
    setTimeout(() => {
      message.style.opacity = "1";
    }, 100);
    
    // Fade out and remove
    setTimeout(() => {
      message.style.opacity = "0";
      setTimeout(() => {
        message.remove();
      }, 1000);
    }, 7000);
  }
  
  // Updated check win condition to include efficiency achievements
  function checkWinCondition() {
    if (!gameActive || goalAchieved) return;
    
    // Win if p-value crosses the 0.05 threshold in the desired direction
    if (initialPValue !== null && currentPValue !== null) {
      const targetThreshold = 0.05;
      
      let winAchieved = false;
      let winMessage = "";
      
      if (targetPValue.includes("< 0.05") && currentPValue < targetThreshold) {
        // Win if we started above threshold and got below
        if (initialPValue >= targetThreshold) {
          winAchieved = true;
          winMessage = "Congratulations! Youve successfully reduced the p-value below 0.05, making the result statistically significant!";
        }
        // Special case: if we started below threshold and are still below
        else if (currentPValue <= initialPValue * 0.5) {
          // If weve halved the p-value, thats also a win
          winAchieved = true;
          winMessage = "Excellent work! Youve halved the p-value, making the result even more significant!";
        }
      }
      else if (targetPValue.includes("≥ 0.05") && currentPValue >= targetThreshold) {
        // Win if we started below threshold and got above
        if (initialPValue < targetThreshold) {
          winAchieved = true;
          winMessage = "Congratulations! Youve successfully increased the p-value above 0.05, making the result statistically non-significant!";
        }
        // Special case: if we started above threshold and increased further
        else if (currentPValue >= initialPValue * 1.5) {
          // If weve increased the p-value by 50%, thats also a win
          winAchieved = true;
          winMessage = "Well done! Youve increased the p-value by over 50%, further supporting the null hypothesis!";
        }
      }
      
      if (winAchieved) {
        console.log("Win condition met! Target: " + targetPValue + ", Current: " + currentPValue);
        goalAchieved = true;
        
        // Show a visual celebration effect
        createVictoryCelebration();
        
        // Check achievements before ending game
        checkEndgameAchievements();
        
        // End the game with the specific win message
        endGame(true, winMessage);
      }
    }
  }
  
  // NEW: Check for endgame achievements
  function checkEndgameAchievements() {
    // Check for Minimal Impact achievement
    if (bricksHitThisGame <= 5 && !achievements.minimalImpact) {
      achievements.minimalImpact = true;
      updateScore(750);
      showAchievementPopup("Minimal Impact! +750");
    }
    
    // Check for Perfect Execution
    if (shotsCount <= 3 && bricksHitThisGame <= 5 && !achievements.perfectExecution) {
      achievements.perfectExecution = true;
      updateScore(1200);
      showAchievementPopup("Perfect Execution! +1200");
    }
    
    // Check for Against The Odds
    if ((initialPValue <= 0.01 || initialPValue >= 0.3) && !achievements.againstTheOdds) {
      achievements.againstTheOdds = true;
      updateScore(800);
      showAchievementPopup("Against The Odds! +800");
    }
  }
  
  // Add a victory celebration effect
  function createVictoryCelebration() {
    // Create firework-like particle effects at multiple positions
    const totalFireworks = 5;
    
    for (let i = 0; i < totalFireworks; i++) {
      // Create particles at random positions around the screen
      const x = (Math.random() - 0.5) * 50;
      const y = 10 + Math.random() * 30;
      const z = -10 + (Math.random() - 0.5) * 20;
      
      createFireworkEffect(new THREE.Vector3(x, y, z));
    }
  }
  
  function createFireworkEffect(position) {
    // Create particle explosion
    const particleCount = 30;
    const particleGroup = new THREE.Group();
    
    // Colors for particles - bright celebration colors
    const celebrationColors = [0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00, 0xFF00FF, 0x00FFFF, 0xFFFFFF];
    
    for (let i = 0; i < particleCount; i++) {
      // Create a small colored sphere for each particle
      const size = Math.random() * 0.6 + 0.2;
      const geometry = new THREE.SphereGeometry(size, 8, 8);
      const material = new THREE.MeshBasicMaterial({
        color: celebrationColors[Math.floor(Math.random() * celebrationColors.length)],
        transparent: true,
        opacity: 0.9
      });
      
      const particle = new THREE.Mesh(geometry, material);
      particle.position.copy(position);
      
      // Add random velocity in all directions (like fireworks)
      const speed = 10 + Math.random() * 15;
      const angle = Math.random() * Math.PI * 2;
      const height = Math.random() * Math.PI;
      
      particle.userData.velocity = new THREE.Vector3(
        Math.sin(angle) * Math.cos(height) * speed,
        Math.sin(height) * speed,
        Math.cos(angle) * Math.cos(height) * speed
      );
      
      // Add to group
      particleGroup.add(particle);
    }
    
    // Add the particle group to the scene
    scene.add(particleGroup);
    
    // Create animation timeline
    let startTime = Date.now();
    let animationId;
    
    function animateParticles() {
      const elapsed = (Date.now() - startTime) / 1000; // seconds
      
      if (elapsed > 3.0) {
        // Remove particles after animation completes
        scene.remove(particleGroup);
        cancelAnimationFrame(animationId);
        return;
      }
      
      // Update each particle
      particleGroup.children.forEach(particle => {
        // Apply gravity after a short delay
        if (elapsed > 0.5) {
          particle.userData.velocity.y -= 9.8 * 0.016; // gravity * deltaTime
        }
        
        // Update position
        particle.position.x += particle.userData.velocity.x * 0.016;
        particle.position.y += particle.userData.velocity.y * 0.016;
        particle.position.z += particle.userData.velocity.z * 0.016;
        
        // Fade out
        particle.material.opacity = Math.max(0, 0.9 * (1 - elapsed / 3.0));
        
        // Grow slightly and then shrink
        const scale = elapsed < 0.5 ? 
          1 + elapsed : 
          Math.max(0.1, 1.5 - elapsed * 0.5);
        particle.scale.set(scale, scale, scale);
      });
      
      // Continue animation
      animationId = requestAnimationFrame(animateParticles);
    }
    
    // Start animation
    animateParticles();
    
    // Play celebration sound
    soundSystem.play("victory", { 
      volume: 0.6 + Math.random() * 0.4,
      rate: 0.8 + Math.random() * 0.4
    });
  }
  
  // Updated progress bar function to emphasize p-value goal
  function updateGoalProgressBar() {
    // Calculate progress toward goal based on p-value difference
    if (initialPValue === null || currentPValue === null) {
      goalProgressBar.style.width = "0%";
      return;
    }
    
    let targetThreshold = 0.05;
    let progress = 0;
    
    if (targetPValue.includes("< 0.05")) {
      // Goal is to get p-value below 0.05
      if (currentPValue < targetThreshold) {
        progress = 100; // Goal achieved
      } else {
        // Map from initial p-value down to 0.05
        const range = initialPValue - targetThreshold;
        if (range <= 0) {
          progress = 0; // Already below threshold or at threshold
        } else {
          progress = 100 * (1 - ((currentPValue - targetThreshold) / range));
        }
      }
    } else {
      // Goal is to get p-value above 0.05
      if (currentPValue >= targetThreshold) {
        progress = 100; // Goal achieved
      } else {
        // Map from initial p-value up to 0.05
        const range = targetThreshold - initialPValue;
        if (range <= 0) {
          progress = 0; // Already above threshold or at threshold
        } else {
          progress = 100 * ((currentPValue - initialPValue) / range);
        }
      }
    }
    
    // Ensure progress is between 0 and 100
    progress = Math.max(0, Math.min(100, progress));
    goalProgressBar.style.width = progress + "%";
    
    // Change color based on progress
    if (progress >= 100) {
      goalProgressBar.style.backgroundColor = "#4CAF50"; // Green when goal achieved
    } else if (progress >= 75) {
      goalProgressBar.style.backgroundColor = "#8BC34A"; // Light green when close
    } else if (progress >= 50) {
      goalProgressBar.style.backgroundColor = "#FFEB3B"; // Yellow when halfway
    } else if (progress >= 25) {
      goalProgressBar.style.backgroundColor = "#FF9800"; // Orange when started
    } else {
      goalProgressBar.style.backgroundColor = "#F44336"; // Red when far from goal
    }
  }
  
  // Updated game UI to emphasize efficiency scoring
  function updateGameUI() {
    const uiHTML = `
    <div style="font-size: 18px; margin-bottom: 10px; color: #FFD700;">
      ${dragging ? "Pull back to aim! Reticle shows landing point." : "Click and drag the ball to aim!"}
    </div>
      <div style="font-size: 16px; margin-bottom: 10px; color: #FFFFFF;">
        Score: ${score} | Shots: ${shotsCount} | Bricks Hit: ${bricksHitThisGame}
      </div>
        <div style="font-size: 16px; margin-bottom: 10px; color: #FFFFFF;">
          <strong>GOAL:</strong> Get p-value ${targetPValue || "Loading..."}
        </div>
          <div style="font-size: 16px; margin-bottom: 10px; color: ${currentPValue < 0.05 ? "#4CAF50" : "#FF9800"};">
          Current p-value: ${currentPValue ? currentPValue.toFixed(4) : "Loading..."}
          ${currentPValue < 0.05 ? " (Significant)" : " (Not Significant)"}
          </div>
            <div style="font-size: 16px; margin-bottom: 10px; color: #FFFF00;">
            Mean: ${currentMean !== null ? currentMean.toFixed(2) : "Loading..."} (yellow line)
          </div>
            <div style="font-size: 14px; margin-bottom: 10px; color: #BBBBBB;">
            Time: ${timeRemaining.toFixed(0)} seconds
          </div>
            <div style="font-size: 14px; margin-bottom: 10px; color: #FF6347;">
            Shot penalty: ${calculateShotPenalty(shotsCount + 1)} for next shot
          </div>
            `;
          gameUI.innerHTML = uiHTML;
  }
  
  // End game function with clearer messaging about p-value goal
  function endGame(isWin, message) {
    // Stop the game timer
    if (gameTimer) {
      clearInterval(gameTimer);
      gameTimer = null;
    }
    
    // Stop countdown sound if playing
    if (countdownSound && countdownSound.stop) {
      countdownSound.stop();
      countdownSound = null;
    }
    
    // Play victory or game over sound
    if (isWin) {
      soundSystem.play("victory", { volume: 0.8 });
    } else {
      soundSystem.play("gameOver", { volume: 0.7 });
    }
    
    // Calculate end-game bonus if the player won
    let bonus = 0;
    if (isWin) {
      const bonusInfo = calculateGameEndBonus();
      bonus = bonusInfo.total;
      
      // Add bonus to score
      score += bonus;
      
      // Update Shiny with final score
      Shiny.setInputValue("score", score);
      
      // Enhanced victory message with p-value and efficiency information
      message += `<br><br>
        <strong>Final p-value:</strong> ${currentPValue.toFixed(4)}<br>
        <strong>Initial p-value:</strong> ${initialPValue.toFixed(4)}<br>
        <strong>Change:</strong> ${Math.abs(currentPValue - initialPValue).toFixed(4)}<br>
        <strong>Shots taken:</strong> ${shotsCount}<br>
        <strong>Bricks hit:</strong> ${bricksHitThisGame}<br><br>
        Time Bonus: ${bonusInfo.timeBonus}<br>
        Achievement Bonus: ${bonusInfo.achievementBonus}<br>
        Potential Score: ${bonusInfo.potentialScore}<br>
        Total Bonus: ${bonus}`;
    } else {
      // Enhanced game over message with guidance
      message += `<br><br>
        <strong>Current p-value:</strong> ${currentPValue.toFixed(4)}<br>
        <strong>Target:</strong> ${targetPValue}<br><br>
        <em>Tip: Be strategic! Every shot and brick hit costs points.<br>
        Try to achieve your goal with minimal actions!</em>`;
    }
    
    // Set the overlay content
    overlayTitle.innerHTML = isWin ? "Victory!" : "Game Over";
    overlayMessage.innerHTML = message;
    
    // Show the overlay
    gameOverlay.style.visibility = "visible";
    
    // Set game active state
    gameActive = false;
  }
  
  // Modified newGame function with emphasis on efficiency
  function newGame() {
  // Play start game sound
  soundSystem.play("levelUp", {
    volume: 0.8,
    fadeIn: true,
    fadeInDuration: 0.5
  });
  
  // Hide overlay if visible
  gameOverlay.style.visibility = "hidden";
  
  // Reset game state
  shotsCount = 0;
  bricksHitThisGame = 0;
  initialPValue = null;
  currentPValue = null;
  targetPValue = null;
  goalAchieved = false;
  
  resetScoring();
  
  // NEW: Choose a random color for this game
  gameBrickColor = colorOptions[Math.floor(Math.random() * colorOptions.length)];
  console.log("New game brick color:", gameBrickColor.toString(16));
  
  // Clean up all constraints first
  for (let i = world.constraints.length - 1; i >= 0; i--) {
    world.removeConstraint(world.constraints[i]);
  }
  
  // Clean up all projectiles
  projectiles.forEach(proj => {
    if (proj) {
      scene.remove(proj.mesh);
      world.remove(proj.body);
    }
  });
  projectiles = [];
  
  // Clean up all bricks
  bricks.forEach(brick => {
    if (brick.constraint) {
      world.removeConstraint(brick.constraint);
    }
    scene.remove(brick.mesh);
    world.remove(brick.body);
  });
  bricks = [];
  
  // Generate new histogram and bricks
  generateHistogram();
  createBricks();
  
  // Create or update mean visualization
  createMeanVisualization();
  
  // Reset ball back to shooter position and update bands
  ball.position.copy(initialBallPos);
  updateBands();
  reticle.visible = false;
  trajectoryLine.visible = false;
  
  // Update UI
  Shiny.setInputValue("shots", shotsCount);
  Shiny.setInputValue("score", score);
  Shiny.setInputValue("bricksHit", bricksHitThisGame);
  
  // Show initial goal hint message
  showGoalMessage();
  
  // Start game timer
  gameActive = true;
  startGameTimer();
  
  console.log("New game started with mean visualization");
}
  
  // === Initialization Functions ===
    function init() {
      // Set up Three.js scene
      scene = new THREE.Scene();
      
      // Create skybox
      const skyboxLoader = new THREE.CubeTextureLoader();
      const skyboxTexture = skyboxLoader.load([
        "https://raw.githubusercontent.com/mrdoob/three.js/master/examples/textures/cube/MilkyWay/dark-s_px.jpg", // right
        "https://raw.githubusercontent.com/mrdoob/three.js/master/examples/textures/cube/MilkyWay/dark-s_nx.jpg", // left
        "https://raw.githubusercontent.com/mrdoob/three.js/master/examples/textures/cube/MilkyWay/dark-s_py.jpg", // top
        "https://raw.githubusercontent.com/mrdoob/three.js/master/examples/textures/cube/MilkyWay/dark-s_ny.jpg", // bottom
        "https://raw.githubusercontent.com/mrdoob/three.js/master/examples/textures/cube/MilkyWay/dark-s_pz.jpg", // front
        "https://raw.githubusercontent.com/mrdoob/three.js/master/examples/textures/cube/MilkyWay/dark-s_nz.jpg"  // back
      ]);
      scene.background = skyboxTexture;
      
      const aspect = container.clientWidth / container.clientHeight;
      camera = new THREE.PerspectiveCamera(75, aspect, 0.1, 1000);
      camera.position.set(0, 15, 50); // Moved camera back and up for better view
      camera.lookAt(0, 10, 0);
      
      renderer = new THREE.WebGLRenderer({ canvas: canvas, antialias: true });
      renderer.setSize(container.clientWidth, container.clientHeight);
      renderer.shadowMap.enabled = true;
      
      // Set up Cannon.js physics world with gravity
      world = new CANNON.World();
      world.gravity.set(0, gravityStrength, 0); // Added gravity in the y direction
      world.broadphase = new CANNON.NaiveBroadphase();
      world.solver.iterations = 10;
      improvePhysicsSettings(); // Add improved physics settings
      
      addLights();
      createFloor();
      createSlingshot();  // Create shooter, ball, posts, and bands
      
      // Slingshot event listeners
      canvas.addEventListener("mousedown", onMouseDown);
      canvas.addEventListener("mousemove", onMouseMove);
      canvas.addEventListener("mouseup", onMouseUp);
      window.addEventListener("resize", onWindowResize);
      
      // Initialize audio context on first user interaction
      document.addEventListener("click", function resumeAudio() {
        if (soundSystem && soundSystem.resumeAudioContext) {
          soundSystem.resumeAudioContext();
        }
        document.removeEventListener("click", resumeAudio);
      }, { once: true });
      
      animate();
    }
  
  // Enhance the physics settings function for better stability
  function improvePhysicsSettings() {
    // Update physics world settings for better stability
    world.gravity.set(0, gravityStrength * 1.5, 0); // Slightly stronger gravity
    world.solver.iterations = 20; // More iterations for better stability
    world.defaultContactMaterial.contactEquationStiffness = 1e7; // Higher stiffness
    world.defaultContactMaterial.contactEquationRelaxation = 3; // Better relaxation
    world.defaultContactMaterial.friction = 0.8; // More friction to prevent sliding
    
    // Create a constraint solver with more iterations for better constraint solving
    world.solver.iterations = 30;
    world.solver.tolerance = 0.001;
    
    // Create a contact material that will be used for all contacts
    const brickMaterial = new CANNON.Material("brick");
    const contactMaterial = new CANNON.ContactMaterial(
      brickMaterial, 
      brickMaterial, 
      {
        friction: 0.8,
        restitution: 0.1,
        contactEquationStiffness: 1e8,
        contactEquationRelaxation: 3
      }
    );
    world.addContactMaterial(contactMaterial);
  }
  
  function addLights() {
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(10, 20, 15);
    directionalLight.castShadow = true;
    directionalLight.shadow.mapSize.width = 2048;
    directionalLight.shadow.mapSize.height = 2048;
    directionalLight.shadow.camera.near = 0.5;
    directionalLight.shadow.camera.far = 50;
    directionalLight.shadow.camera.left = -30;
    directionalLight.shadow.camera.right = 30;
    directionalLight.shadow.camera.top = 30;
    directionalLight.shadow.camera.bottom = -30;
    scene.add(directionalLight);
  }
  
  function createFloor() {
    const floorSize = FLOOR_SIZE;
    const floorGeometry = new THREE.PlaneGeometry(floorSize, floorSize, 10, 10);
    
    // Load texture for the floor
    const textureLoader = new THREE.TextureLoader();
    const floorTexture = textureLoader.load("https://cld.pt/dl/download/65aeb9c1-b9e6-43b8-829c-c61a3aaddc01/Moon_001_SD/Moon_001_COLOR.jpg?download=true");
    const floorBumpMap = textureLoader.load("https://cld.pt/dl/download/65aeb9c1-b9e6-43b8-829c-c61a3aaddc01/Moon_001_SD/Moon_001_NORM.jpg?download=true");
    
    // Make the texture repeat many times across the floor
    floorTexture.wrapS = THREE.RepeatWrapping;
    floorTexture.wrapT = THREE.RepeatWrapping;
    floorTexture.repeat.set(8, 8);
    
    // Also make the bump map repeat
      floorBumpMap.wrapS = THREE.RepeatWrapping;
    floorBumpMap.wrapT = THREE.RepeatWrapping;
    floorBumpMap.repeat.set(8, 8);
    
    // Create floor material with texture and bump mapping
    const floorMaterial = new THREE.MeshStandardMaterial({ 
      map: floorTexture,
      bumpMap: floorBumpMap,
      bumpScale: 0.1,
      roughness: 0.6, 
      metalness: 0.2
    });
    
    const floorMesh = new THREE.Mesh(floorGeometry, floorMaterial);
    floorMesh.rotation.x = -Math.PI / 2;
    floorMesh.receiveShadow = true;
    scene.add(floorMesh);
    
    const floorShape = new CANNON.Plane();
    const floorBody = new CANNON.Body({ mass: 0, shape: floorShape });
    floorBody.quaternion.setFromAxisAngle(new CANNON.Vec3(1, 0, 0), -Math.PI / 2);
    world.addBody(floorBody);
  }
  
  function createSlingshot() {
    // Define the resting position for the ball (pouch) - moved up for more pulling space
    const shooterPos = new THREE.Vector3();
    shooterPos.copy(camera.position);
    shooterPos.z -= 10; // Moved out further from camera
    shooterPos.y = 10;  // Lowered position
    initialBallPos.copy(shooterPos);
    
    // Create a visible shooter (optional: can be hidden if you prefer)
    const shooterGeometry = new THREE.SphereGeometry(0.3, 16, 16);
    const shooterMaterial = new THREE.MeshStandardMaterial({ color: 0x0095DD, emissive: 0x0033FF, emissiveIntensity: 0.5 });
    shooter = new THREE.Mesh(shooterGeometry, shooterMaterial);
    shooter.position.copy(shooterPos);
    shooter.castShadow = true;
    scene.add(shooter);
    
    // Create the ball (initially coincident with shooter)
    const ballGeometry = new THREE.SphereGeometry(projectileSize, 16, 16);
    const ballMaterial = new THREE.MeshStandardMaterial({ color: 0x0095DD, metalness: 0.3, roughness: 0.6 });
    ball = new THREE.Mesh(ballGeometry, ballMaterial);
    ball.position.copy(shooterPos);
    ball.castShadow = true;
    scene.add(ball);
    
    // Create slingshot posts (simple cylinders)
    const postGeometry = new THREE.CylinderGeometry(0.1, 0.1, 1.5, 12);
    const postMaterial = new THREE.MeshStandardMaterial({ color: 0x654321 });
    leftPost = new THREE.Mesh(postGeometry, postMaterial);
    rightPost = new THREE.Mesh(postGeometry, postMaterial);
    // Position posts relative to shooterPos
    leftPost.position.copy(shooterPos).add(new THREE.Vector3(-0.5, 0, 0));
    rightPost.position.copy(shooterPos).add(new THREE.Vector3(0.5, 0, 0));
    leftPost.castShadow = true;
    rightPost.castShadow = true;
    scene.add(leftPost);
    scene.add(rightPost);
    
    // Create rubber band lines (as THREE.Line objects)
    const bandMaterial = new THREE.LineBasicMaterial({ color: 0xff0000, linewidth: 2 });
    let bandGeomLeft = new THREE.BufferGeometry().setFromPoints([leftPost.position, ball.position]);
    bandLeft = new THREE.Line(bandGeomLeft, bandMaterial);
    let bandGeomRight = new THREE.BufferGeometry().setFromPoints([rightPost.position, ball.position]);
    bandRight = new THREE.Line(bandGeomRight, bandMaterial);
    scene.add(bandLeft);
    scene.add(bandRight);
    
    // Create reticle for landing point prediction
    const reticleGeometry = new THREE.RingGeometry(0.5, 0.7, 32);
    const reticleMaterial = new THREE.MeshBasicMaterial({ color: 0xff0000 });
    reticle = new THREE.Mesh(reticleGeometry, reticleMaterial);
    reticle.rotation.x = -Math.PI / 2; // Lay flat
    reticle.visible = false;
    scene.add(reticle);
    
    // Create trajectory visualization line
    const trajectoryMaterial = new THREE.LineDashedMaterial({
      color: 0xff0000,
      dashSize: 0.5,
      gapSize: 0.3,
    });
    const trajectoryGeometry = new THREE.BufferGeometry();
    trajectoryLine = new THREE.Line(trajectoryGeometry, trajectoryMaterial);
    trajectoryLine.visible = false;
    scene.add(trajectoryLine);
  }
  
  // Function to create the mean line
  function createMeanVisualization() {
    console.log("Creating mean visualization");
    
    // If the mean line already exists, remove it first
    if (meanLine) {
      scene.remove(meanLine);
      meanLine = null;
    }
    
    // Create a bright yellow line for the mean - increased line width to 5
    const meanMaterial = new THREE.LineBasicMaterial({ 
      color: 0xffff00, 
      linewidth: 5
    });
    
    // Create initial points (will be updated when we have data)
    // Increased the height of the line to 50 (from 30)
    const points = [
      new THREE.Vector3(0, 0, -10),
      new THREE.Vector3(0, 50, -10)  // Increased height from 30 to 50
    ];
    
    // Create the line geometry and mesh
    const meanGeometry = new THREE.BufferGeometry().setFromPoints(points);
    meanLine = new THREE.Line(meanGeometry, meanMaterial);
    scene.add(meanLine);
    
    console.log("Mean line created and added to scene");
  }
  
  // Function to create bin value labels
  function createValueLabels() {
    console.log("Creating bin value labels");
    
    // Remove any existing labels
    valueLabels.forEach(label => {
      if (label) scene.remove(label);
    });
    valueLabels = [];
    
    if (!histogram || histogram.length === 0) {
      console.log("No histogram data available for labels");
      return;
    }
    
    // Calculate positions based on histogram bins
    const binWidth = BRICK_WIDTH + BRICK_SPACING;
    const totalWidth = histogram.length * binWidth;
    const startX = -totalWidth / 2 + binWidth / 2;
    
    for (let i = 0; i < histogram.length; i++) {
      // Create canvas for text
      const canvas = document.createElement("canvas");
      const context = canvas.getContext("2d");
      canvas.width = 64;
      canvas.height = 32;
      
      // Draw text (bin index)
      context.fillStyle = "white";
      context.font = "Bold 24px Arial";
      context.textAlign = "center";
      context.textBaseline = "middle";
      context.fillText(i.toString(), 32, 16);
      
      // Create sprite with canvas texture
      const texture = new THREE.CanvasTexture(canvas);
      const material = new THREE.SpriteMaterial({ 
        map: texture,
        transparent: true
      });
      const label = new THREE.Sprite(material);
      
      // Position label - position at the front of the histogram above floor level
      const x = startX + i * binWidth;
      // Changed Z position from -9.5 to -8 to move labels in front of histogram
      // Changed Y position from 0.5 to 1.0 to raise them slightly
      label.position.set(x, 1.0, -8);  
      label.scale.set(3, 1.5, 1);  // Make it readable
      
      scene.add(label);
      valueLabels.push(label);
    }
    console.log("Created " + valueLabels.length + " bin labels");
  }
  
  // Function to update the mean line position
  function updateMeanLine() {
    if (!meanLine || !histogram || histogram.length === 0 || currentMean === null) {
      console.log("Cannot update mean line - missing required data");
      return;
    }
    
    console.log("Updating mean line to position for mean:", currentMean);
    
    // Calculate bin statistics
    const binWidth = BRICK_WIDTH + BRICK_SPACING;
    const totalWidth = histogram.length * binWidth;
    const startX = -totalWidth / 2 + binWidth / 2;
    
    // Calculate mean bin position
    // For simplicity, map the current mean to the histogram bin positions
    const meanX = startX + currentMean * binWidth;
    
    // Update the line geometry
    // Increased the height of the line to 50 (from 30)
    const points = [
      new THREE.Vector3(meanX, 0, -10),     // Floor level
      new THREE.Vector3(meanX, 50, -10)     // Increased height from 30 to 50
    ];
    
    meanLine.geometry.setFromPoints(points);
    meanLine.geometry.computeBoundingSphere();
    
    console.log("Mean line updated to position x:", meanX);
  }
  
  function updateBands() {
    // Update rubber band lines to connect from posts to the current ball position
    if (bandLeft && bandRight) {
      bandLeft.geometry.setFromPoints([leftPost.position, ball.position]);
      bandRight.geometry.setFromPoints([rightPost.position, ball.position]);
    }
  }
  
  function onWindowResize() {
    const aspect = container.clientWidth / container.clientHeight;
    camera.aspect = aspect;
    camera.updateProjectionMatrix();
    renderer.setSize(container.clientWidth, container.clientHeight);
  }
  
  // === Slingshot Drag Handlers ===
    function onMouseDown(event) {
      if (!gameActive) return; // Prevent interaction when game is not active
      
      // Check if user clicked near the ball (within a threshold)
      const rect = canvas.getBoundingClientRect();
      const mouseX = event.clientX - rect.left;
      const mouseY = event.clientY - rect.top;
      // Project ball position to screen space
      const ballPos = ball.position.clone();
      ballPos.project(camera);
      const screenX = (ballPos.x + 1) / 2 * rect.width;
      const screenY = (-ballPos.y + 1) / 2 * rect.height;
      const dist = Math.sqrt(Math.pow(screenX - mouseX, 2) + Math.pow(screenY - mouseY, 2));
      if (dist < 30) {  // 30 pixel threshold
        dragging = true;
        initialMouse = { x: event.clientX, y: event.clientY };
        
        // Play click sound when starting to drag
        soundSystem.play("click", { volume: 0.4, rate: 0.8 });
      }
    }
  
  function onMouseMove(event) {
    if (!gameActive) return; // Prevent interaction when game is not active
    
    if (dragging) {
      // Get cursor position in screen space
      const rect = canvas.getBoundingClientRect();
      const mouseX = event.clientX - rect.left;
      const mouseY = event.clientY - rect.top;
      
      // Convert to normalized device coordinates (-1 to +1)
      const ndcX = (mouseX / rect.width) * 2 - 1;
      const ndcY = -(mouseY / rect.height) * 2 + 1;
      
      // Set up raycaster to convert screen position to 3D position
      const raycaster = new THREE.Raycaster();
      raycaster.setFromCamera(new THREE.Vector2(ndcX, ndcY), camera);
      
      // Define a plane at the balls Z coordinate to raycast against
          const dragPlane = new THREE.Plane(new THREE.Vector3(0, 0, 1), -ball.position.z);
          
          // Find the intersection point between the ray and the plane
          const intersectPoint = new THREE.Vector3();
          raycaster.ray.intersectPlane(dragPlane, intersectPoint);
          
          // Move ball to cursor position, but constrain how far it can move from initial position
          if (intersectPoint) {
            // Calculate offset from initial position
            const offset = new THREE.Vector3().subVectors(intersectPoint, initialBallPos);
            
            // Limit how far the ball can be pulled
            const maxDistance = 10;
            if (offset.length() > maxDistance) {
              offset.normalize().multiplyScalar(maxDistance);
            }
            
            // Update ball position and record dragging offset
            ball.position.copy(initialBallPos).add(offset);
            
            // For trajectory prediction, well use a diagonally opposite offset
      // Create diagonally opposite vector by negating both x and y components
      const diagonalOpposite = new THREE.Vector3(-offset.x, -offset.y, offset.z);
      dragOffset = diagonalOpposite.clone();
      
      updateBands();
      updateTrajectoryPrediction();
      
      // Play tension sound based on drag distance
      const tension = Math.min(offset.length() / maxDistance, 1);
      // Only play when significant change occurs (to avoid too many sounds)
      if (Math.random() < 0.05) {
        soundSystem.play("click", {
          volume: 0.1 * tension,
          rate: 0.5 + tension * 0.5
        });
      }
    }
  }
  }

function updateTrajectoryPrediction() {
  if (!dragging || !reticle) return;
  
  // Use the diagonally opposite direction for trajectory prediction
  const impulseVec = dragOffset.clone().multiplyScalar(impulseFactor);
  impulseVec.z = -powerMultiplier; // Force movement towards histogram
  
  // Predict landing point using physics equations
  const mass = 5; // Same as what well use for the actual projectile
        const velocity = new THREE.Vector3().copy(impulseVec).divideScalar(mass);
        
        // Time to reach histogram (z=0) plane
        // Using z = z0 + vz*t formula and solving for t
        const t = -ball.position.z / velocity.z;
        
        // Calculate x and y positions at that time
        // Using formula: position = initial_position + velocity*time + 0.5*acceleration*time^2
        const predictedX = ball.position.x + velocity.x * t;
        const predictedY = ball.position.y + velocity.y * t + 0.5 * gravityStrength * t * t;
        
        // Update reticle position
        reticle.position.set(predictedX, 0.1, 0); // Just above the floor
        reticle.visible = true;
        
        // Create a trajectory visualization with multiple points
        const points = [];
        const steps = 20; // Number of points in trajectory
        for (let i = 0; i <= steps; i++) {
          const stepTime = (t / steps) * i;
          const x = ball.position.x + velocity.x * stepTime;
          const y = ball.position.y + velocity.y * stepTime + 0.5 * gravityStrength * stepTime * stepTime;
          const z = ball.position.z + velocity.z * stepTime;
          points.push(new THREE.Vector3(x, y, z));
        }
        
        trajectoryLine.geometry.setFromPoints(points);
        trajectoryLine.visible = true;
        trajectoryLine.computeLineDistances(); // Required for dashed lines
      }
      
      function onMouseUp(event) {
        if (!gameActive) return; // Prevent interaction when game is not active
        
        if (dragging) {
          dragging = false;
          
          // Calculate the impulse based on the vector from initialBallPos to ball position,
          // but diagonally opposite (negating both x and y components)
          const offset = new THREE.Vector3().subVectors(ball.position, initialBallPos);
          
          // Create diagonally opposite vector for launch
          const impulseVec = new THREE.Vector3(-offset.x, -offset.y, 0).multiplyScalar(impulseFactor);
          
          // Always add a fixed negative z impulse so ball moves toward histogram
          impulseVec.z = -powerMultiplier;
          
          // Calculate launch power based on pull distance
          const pullDistance = offset.length();
          const maxDistance = 10;
          const launchPower = Math.min(pullDistance / maxDistance, 1);
          
          // Play slingshot sound with volume based on power
          soundSystem.play("slingshot", {
            volume: 0.5 + launchPower * 0.5,
            rate: 3.0 + launchPower * 0.4
          });
          
          // Apply shot penalty before launching
          const shotPenalty = calculateShotPenalty(shotsCount + 1);
          if (shotPenalty < 0) {
            updateScore(shotPenalty);
          }
          
          launchBall(impulseVec);
          
          // Reset ball position and hide bands (they will be recreated on next shot)
          ball.position.copy(initialBallPos);
          updateBands();
          reticle.visible = false;
          trajectoryLine.visible = false;
        }
      }
      
      function launchBall(impulse) {
        // Create a new ball mesh for the projectile using the current projectile size
        console.log("Launching ball with size:", projectileSize);
        const ballGeometry = new THREE.SphereGeometry(projectileSize, 16, 16);
        const ballMaterial = new THREE.MeshStandardMaterial({ color: 0x0095DD, metalness: 0.3, roughness: 0.6 });
        const projBall = new THREE.Mesh(ballGeometry, ballMaterial);
        projBall.position.copy(ball.position); // Launch from current ball position
        projBall.castShadow = true;
        scene.add(projBall);
        
        // Create physics body for the ball
        const shape = new CANNON.Sphere(projectileSize);
        ballBody = new CANNON.Body({ mass: 5, shape: shape, linearDamping: 0.1, angularDamping: 0.1 });
        ballBody.position.copy(projBall.position);
        ballBody.collisionResponse = true; // Enable collision response
        ballBody.applyImpulse(impulse, ballBody.position);
        world.addBody(ballBody);
        projectiles.push({ mesh: projBall, body: ballBody, createdAt: Date.now(), id: Date.now() }); // Added ID for tracking
        shotsCount++;
        Shiny.setInputValue("shots", shotsCount);
      }
      
      // === Modified Histogram and Brick Functions ===
      function generateHistogram() {
        const numBins = Math.floor(Math.random() * 5) + 6; // 6-10 bins
        const binWidth = BRICK_WIDTH + BRICK_SPACING;
        const totalWidth = numBins * binWidth;
        const startX = -totalWidth / 2 + binWidth / 2;
        histogram = [];
        const generateNormal = Math.random() < 0.5;
        Shiny.setInputValue("targetDistribution", generateNormal ? "normal" : "non-normal");
        
        // Always ensure we have a valid distribution for t-test calculation
        if (generateNormal) {
          // Normal distribution - ensure enough variation for t-test
          const mean = numBins / 2;
          const stdDev = numBins / 4;
          
          // Keep track of total bricks to ensure we have enough
          let totalBricks = 0;
          
          for (let i = 0; i < numBins; i++) {
            const z = (i - mean) / stdDev;
            const heightFactor = Math.exp(-(z * z) / 2);
            
            // Ensure each bin has at least 1 brick, with more near the center
            let brickCount = Math.floor(heightFactor * 10) + 2;
            
            // Add slight random variation but maintain the bell curve shape
            brickCount += Math.floor(Math.random() * 3) - 1;
            
            // Ensure at least 1 brick in every bin and cap at 15
            brickCount = Math.max(1, Math.min(15, brickCount));
            
            totalBricks += brickCount;
            
            histogram.push({ 
              x: startX + i * binWidth, 
              count: brickCount, 
              binIndex: i 
            });
          }
          
          // If we have very few total bricks, increase some bin counts
          if (totalBricks < numBins * 3) {
            // Add more bricks to ensure good variation
            for (let i = 0; i < numBins; i++) {
              if (histogram[i].count == 1) {
                // Increase 1-brick bins to have 2-3 bricks
                histogram[i].count += 1 + Math.floor(Math.random() * 2);
              }
            }
          }
          
        } else {
          // Non-normal distributions - create one with good variation
          const distributionType = Math.floor(Math.random() * 3);
          
          if (distributionType === 0) {
            // Bimodal distribution - two clear peaks
            const peak1 = Math.floor(numBins / 3);
            const peak2 = Math.floor(2 * numBins / 3);
            
            for (let i = 0; i < numBins; i++) {
              const distFromPeak1 = Math.abs(i - peak1);
              const distFromPeak2 = Math.abs(i - peak2);
              const minDist = Math.min(distFromPeak1, distFromPeak2);
              
              // Create two clear peaks with valleys between
              let brickCount = 15 - minDist * 2;
              
              // Ensure at least 1 brick in every bin
              brickCount = Math.max(2, Math.min(15, brickCount));
              
              histogram.push({ 
                x: startX + i * binWidth, 
                count: brickCount, 
                binIndex: i 
              });
            }
            
          } else if (distributionType === 1) {
            // Exponential-like distribution
            for (let i = 0; i < numBins; i++) {
              const factor = Math.exp(-0.3 * i); // Made decay slower for more variation
              
              // Create exponential distribution
              let brickCount = Math.floor(factor * 15);
              
              // Ensure at least 2 bricks in every bin for valid t-test
              brickCount = Math.max(2, Math.min(15, brickCount));
              
              histogram.push({ 
                x: startX + i * binWidth, 
                count: brickCount, 
                binIndex: i 
              });
            }
            
          } else {
            // U-shaped distribution
            for (let i = 0; i < numBins; i++) {
              const normalizedPos = i / (numBins - 1);
              let uShape = 1 - 4 * Math.pow(normalizedPos - 0.5, 2);
              uShape = 1 - uShape;
              
              // Create U-shape
              let brickCount = Math.floor(uShape * 12) + 3; // Minimum of 3 bricks
              
              histogram.push({ 
                x: startX + i * binWidth, 
                count: brickCount, 
                binIndex: i 
              });
            }
          }
        }
        
        // Verify that we have enough variation for a t-test
        const histogramValues = histogram.map(bin => bin.count);
        const mean = histogramValues.reduce((sum, val) => sum + val, 0) / histogramValues.length;
        
        // Ensure we have some variance in the values
        let hasVariance = false;
        for (let i = 0; i < histogramValues.length; i++) {
          if (Math.abs(histogramValues[i] - mean) > 1) {
            hasVariance = true;
            break;
          }
        }
        
        // If no variance, adjust some values to create variance
        if (!hasVariance) {
          // Modify at least two bins to ensure variance
          const bin1 = Math.floor(Math.random() * numBins);
          let bin2 = Math.floor(Math.random() * numBins);
          while (bin2 === bin1) {
            bin2 = Math.floor(Math.random() * numBins);
          }
          
          // Increase one bin and decrease another
          histogram[bin1].count = Math.min(15, histogram[bin1].count + 3);
          histogram[bin2].count = Math.max(1, histogram[bin2].count - 2);
        }
        
        // Save initial histogram for reference
        initialHistogram = JSON.parse(JSON.stringify(histogram));
        const finalHistogramValues = histogram.map(bin => bin.count);
        
        // Send to R for processing
        Shiny.setInputValue("initialHistogramData", finalHistogramValues);
        Shiny.setInputValue("histogramData", finalHistogramValues);
        
        // Create value labels after generating histogram
        createValueLabels();
        
        console.log("Generated new histogram with " + histogram.length + " bins");
      }
      
      // Modified createBricks function to add configuration that limits rotation and movement
      function createBricks() {
        bricks = [];
        // Remove old bricks from scene
        scene.children.forEach(child => {
          if (child.userData && child.userData.isBrick) {
            scene.remove(child);
          }
        });
        
        histogram.forEach(bin => {
          for (let level = 0; level < bin.count; level++) {
            const brickColor = gameBrickColor; // Use the single game color
            const geometry = new THREE.BoxGeometry(BRICK_WIDTH, BRICK_HEIGHT, BRICK_DEPTH);
            const material = new THREE.MeshStandardMaterial({ color: brickColor, roughness: 0.7, metalness: 0.2 });
            const brickMesh = new THREE.Mesh(geometry, material);
            const x = bin.x;
            const y = BRICK_HEIGHT / 2 + level * (BRICK_HEIGHT + BRICK_SPACING);
            const z = -10;
            brickMesh.position.set(x, y, z);
            brickMesh.castShadow = true;
            brickMesh.receiveShadow = true;
            brickMesh.userData = { isBrick: true, binIndex: bin.binIndex, level: level };
            scene.add(brickMesh);
            
            // Create the physics body
            const halfExtents = new CANNON.Vec3(BRICK_WIDTH/2, BRICK_HEIGHT/2, BRICK_DEPTH/2);
            const shape = new CANNON.Box(halfExtents);
            const body = new CANNON.Body({
              mass: 1,
              shape: shape,
              position: new CANNON.Vec3(x, y, z),
              linearDamping: 0.8, // Increased damping to reduce bouncing
              angularDamping: 0.95 // High angular damping to reduce rotation
            });
            
            // Lock rotation on x and z axes to keep brick upright
            body.fixedRotation = true;
            body.updateMassProperties();
            
            // Increase friction to help stacks stay stable
            body.material = new CANNON.Material();
            body.material.friction = 0.8; // Increased friction
            body.material.restitution = 0.1; // Low restitution (bounciness)
            
            // Add additional shape as a constraint to keep bricks in line
            // This creates invisible walls on both sides of each bin
            const wallShape = new CANNON.Box(new CANNON.Vec3(0.1, BRICK_HEIGHT/2, BRICK_DEPTH/2));
            const wallOffsetLeft = new CANNON.Vec3(-(BRICK_WIDTH/2 - 0.1), 0, 0);
            const wallOffsetRight = new CANNON.Vec3(BRICK_WIDTH/2 - 0.1, 0, 0);
            body.addShape(wallShape, wallOffsetLeft);
            body.addShape(wallShape, wallOffsetRight);
            
            // Sleep the body initially (for performance)
            body.sleep();
            world.addBody(body);
            
            bricks.push({ 
              mesh: brickMesh, 
              body: body, 
              binIndex: bin.binIndex, 
              level: level, 
              isRemoved: false,
              constraint: null,
              ghostBody: null
            });
          }
        });
      }
      
      // Create particle effect for brick hits
      function createHitEffect(position) {
        // Create particle explosion
        const particleCount = 8;
        const particleGroup = new THREE.Group();
        
        for (let i = 0; i < particleCount; i++) {
          // Create a small colored sphere for each particle
          const size = Math.random() * 0.3 + 0.1;
          const geometry = new THREE.SphereGeometry(size, 8, 8);
          const material = new THREE.MeshBasicMaterial({
            color: gameBrickColor, // Use the games single color
            transparent: true,
            opacity: 0.8
          });
          
          const particle = new THREE.Mesh(geometry, material);
          particle.position.copy(position);
          
          // Add random velocity for animation
          particle.userData.velocity = new THREE.Vector3(
            (Math.random() - 0.5) * 10,
            Math.random() * 15,
            (Math.random() - 0.5) * 10
          );
          
          // Add to group
          particleGroup.add(particle);
        }
        
        // Add the particle group to the scene
        scene.add(particleGroup);
        
        // Create animation timeline
        let startTime = Date.now();
        let animationId;
        
        function animateParticles() {
          const elapsed = (Date.now() - startTime) / 1000; // seconds
          
          if (elapsed > 1.5) {
            // Remove particles after animation completes
            scene.remove(particleGroup);
            cancelAnimationFrame(animationId);
            return;
          }
          
          // Update each particle
          particleGroup.children.forEach(particle => {
            // Apply gravity
            particle.userData.velocity.y -= 20 * 0.016; // gravity * deltaTime
            
            // Update position
            particle.position.x += particle.userData.velocity.x * 0.016;
            particle.position.y += particle.userData.velocity.y * 0.016;
            particle.position.z += particle.userData.velocity.z * 0.016;
            
            // Fade out
            particle.material.opacity = Math.max(0, 0.8 * (1 - elapsed / 1.5));
          });
          
          // Continue animation
          animationId = requestAnimationFrame(animateParticles);
        }
        
        // Start animation
        animateParticles();
      }
      
      // New function to rearrange all bricks in a bin after a removal
      function rearrangeBricksInBin(binIndex) {
        // Get all remaining (non-removed) bricks in this bin
        const remainingBricks = bricks.filter(b => !b.isRemoved && b.binIndex === binIndex);
        
        // Sort bricks by their current Y position (from bottom to top)
        remainingBricks.sort((a, b) => a.mesh.position.y - b.mesh.position.y);
        
        console.log("Rearranging " + remainingBricks.length + " bricks in bin " + binIndex);
        
        // Reassign levels from 0 upward and update positions
        remainingBricks.forEach((brick, index) => {
          // Record original level for logging
          const oldLevel = brick.level;
          
          // Assign new level
          brick.level = index;
          
          // Calculate new position based on level
          const newY = BRICK_HEIGHT / 2 + index * (BRICK_HEIGHT + BRICK_SPACING);
          
          // Update positions
          brick.mesh.position.y = newY;
          brick.body.position.y = newY;
          
          console.log("Moved brick from level " + oldLevel + " to " + index);
        });
        
        // Only update the histogram data if no update is currently in progress
        if (!pValueUpdateInProgress) {
          setTimeout(updateHistogramData, 500);
        }
      }
      
      // New function to reorganize brick levels after theyve settled
  function reorganizeBrickLevels() {
    // Group bricks by bin
    for (let binIndex = 0; binIndex < histogram.length; binIndex++) {
      let binBricks = bricks.filter(b => !b.isRemoved && b.binIndex === binIndex);
      
      // Sort by Y position (lowest first)
      binBricks.sort((a, b) => a.mesh.position.y - b.mesh.position.y);
      
      // Assign new level values
      for (let i = 0; i < binBricks.length; i++) {
        binBricks[i].level = i;
      }
    }
  }
  
  // Modify animate function to include hint displays
  function animate() {
    requestAnimationFrame(animate);
    
    if (gameActive) {
      world.step(1/60);
      
      // Update brick positions from physics bodies and check for bin constraints
      bricks.forEach(brick => {
        if (!brick.isRemoved) {
          // Get current position
          const binWidth = BRICK_WIDTH + BRICK_SPACING;
          const totalWidth = histogram.length * binWidth;
          const startX = -totalWidth / 2 + binWidth / 2;
          const xPosition = startX + brick.binIndex * binWidth;
          
          // Force X position to stay aligned with bin center
          // This is a hard constraint approach
          brick.body.position.x = xPosition;
          brick.body.position.z = -10; // Keep Z position fixed
          
          // Update mesh position from physics body
          brick.mesh.position.copy(brick.body.position);
          brick.mesh.quaternion.copy(brick.body.quaternion);
        }
      });
      
      // Update projectile positions from physics bodies
      projectiles.forEach(proj => {
        if (proj) {
          proj.mesh.position.copy(proj.body.position);
          proj.mesh.quaternion.copy(proj.body.quaternion);
        }
      });
      
      // Update the mean line if we have valid data
      if (meanLine && currentMean !== null) {
        updateMeanLine();
      }
      
      handleCollisions();
      
      // Show hint if the player is struggling - every 5 shots
      if (shotsCount % 5 === 0 && shotsCount > 0 && !goalAchieved) {
        showHint();
      }
      
      // Check win condition
      checkWinCondition();
    }
    
    updateGameUI();
    renderer.render(scene, camera);
    
    // Clean up old projectiles that have fallen off the scene
    projectiles = projectiles.filter(proj => {
      const age = Date.now() - proj.createdAt;
      if (age > 10000 || proj.mesh.position.y < -10) {
        scene.remove(proj.mesh);
        world.remove(proj.body);
        return false;
      }
      return true;
    });
  }
  
  init();
  
  $("#newGame").click(function() {
    soundSystem.play("click", { volume: 0.5 });
    newGame();
  });
  
  $("#overlayButton").off("click").on("click", function() {
    console.log("Play Again button clicked");
    soundSystem.play("click", { volume: 0.5 });
    gameOverlay.style.visibility = "hidden";
    setTimeout(function() {
      newGame();
    }, 100);
  });
  
  // Initialize the game
  setTimeout(function() {
    newGame();
  }, 1000);
});
  '))
)

server <- function(input, output, session) {
  shots <- reactiveVal(0)
  bricksHit <- reactiveVal(0)
  initialPValue <- reactiveVal(NA)
  currentPValue <- reactiveVal(NA)
  initialMean <- reactiveVal(NA)
  currentMean <- reactiveVal(NA)
  testValue <- reactiveVal(NA)
  targetPValue <- reactiveVal("")
  goalAchieved <- reactiveVal(FALSE)
  targetDistribution <- reactiveVal("unknown")
  score <- reactiveVal(0)
  highScore <- reactiveVal(0)
  
  observeEvent(input$shots, {
    shots(input$shots)
  })
  
  observeEvent(input$bricksHit, {
    bricksHit(input$bricksHit)
  })
  
  observeEvent(input$targetDistribution, {
    targetDistribution(input$targetDistribution)
  })
  
  observeEvent(input$targetPValueType, {
    targetPValue(input$targetPValueType)
  })
  
  observeEvent(input$score, {
    score(input$score)
  })
  
  observeEvent(input$highScore, {
    highScore(input$highScore)
  })
  
  output$shotsCount <- renderText({ shots() })
  output$bricksHitCount <- renderText({ bricksHit() })
  output$initialPValue <- renderText({ if (is.na(initialPValue())) "N/A" else initialPValue() })
  output$currentPValue <- renderText({ if (is.na(currentPValue())) "N/A" else currentPValue() })
  output$initialMean <- renderText({ if (is.na(initialMean())) "N/A" else initialMean() })
  output$currentMean <- renderText({ if (is.na(currentMean())) "N/A" else currentMean() })
  output$testValue <- renderText({ if (is.na(testValue())) "N/A" else testValue() })
  output$targetPValue <- renderText({ targetPValue() })
  output$scoreDisplay <- renderText({ score() })
  output$highScoreDisplay <- renderText({ highScore() })
  output$goalStatus <- renderText({
    if (goalAchieved()) {
      " ✓ Goal achieved!"
    } else if (!is.na(initialPValue()) && !is.na(currentPValue())) {
      " ✗ Keep trying!"
    } else {
      ""
    }
  })
  
  output$interpretation <- renderText({
    if (is.na(currentPValue())) {
      "Not enough data for t-test (need at least 2 bins)"
    } else if (currentPValue() < 0.05) {
      paste0("The histogram mean is significantly different from ", testValue(), " (p < 0.05)")
    } else {
      paste0("The histogram mean is not significantly different from ", testValue(), " (p ≥ 0.05)")
    }
  })
  
  observeEvent(input$initialHistogramData, {
    hist_data <- input$initialHistogramData
    if (length(hist_data) >= 2) {
      # Calculate mean of the initial histogram data
      # The mean is calculated as a weighted average of bin indices
      weighted_sum <- sum(sapply(1:length(hist_data), function(i) (i-1) * hist_data[i]))
      total_count <- sum(hist_data)
      mean_value <- weighted_sum / total_count
      
      initialMean(round(mean_value, 2))
      currentMean(round(mean_value, 2))
      
      # Send the initial mean to JavaScript
      session$sendCustomMessage("updateCurrentMean", mean_value)
      
      # Set a test value slightly different from the mean
      # This will be our hypothesized population mean
      test_val <- round(mean_value * (1 + ifelse(runif(1) > 0.5, 0.2, -0.2)), 2)
      testValue(test_val)
      
      # Perform t-test against this hypothesized value
      test_result <- t.test(hist_data, mu = test_val)
      p <- round(test_result$p.value, 4)
      initialPValue(p)
      currentPValue(p)
      session$sendCustomMessage("updateInitialPValue", p)
    } else {
      initialPValue(NA)
      currentPValue(NA)
      initialMean(NA)
      currentMean(NA)
      testValue(NA)
    }
  })
  
  observeEvent(input$histogramData, {
    if (is.null(input$initialHistogramData) || identical(input$histogramData, input$initialHistogramData)) {
      return()
    }
    
    hist_data <- input$histogramData
    if (length(hist_data) >= 2) {
      # Calculate the current mean
      weighted_sum <- sum(sapply(1:length(hist_data), function(i) (i-1) * hist_data[i]))
      total_count <- sum(hist_data)
      curr_mean <- weighted_sum / total_count
      
      # Update the reactive value
      currentMean(round(curr_mean, 2))
      
      # Send the current mean to JavaScript
      session$sendCustomMessage("updateCurrentMean", curr_mean)
      
      # Perform t-test against our test value
      test_result <- t.test(hist_data, mu = testValue())
      p <- round(test_result$p.value, 4)
      currentPValue(p)
      session$sendCustomMessage("updateCurrentPValue", p)
      
      # Check if goal is achieved (p-value crossed the 0.05 threshold)
      if (!is.na(initialPValue())) {
        if ((initialPValue() >= 0.05 && p < 0.05) || (initialPValue() < 0.05 && p >= 0.05)) {
          goalAchieved(TRUE)
        } else {
          goalAchieved(FALSE)
        }
      }
    } else {
      currentPValue(NA)
      currentMean(NA)
    }
  })
  
  observeEvent(input$shots, {
    shots(input$shots)
  })
  
  observeEvent(input$projectileSize, {
    session$sendCustomMessage("updateProjectileSize", input$projectileSize)
  })
}

# Launch the application
shinyApp(ui = ui, server = server)