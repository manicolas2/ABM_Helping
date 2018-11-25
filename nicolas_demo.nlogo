extensions [ gis ]

turtles-own [
  age
  gender
]

patches-own [ patch-input ]

needys-own [
  scenario
  health-condition?
  helped?
]

helpers-own [
  help-capacity
  helping?
  target
  has-helped?
]

globals [
  help-from-woman?
  help-from-man?
  radius
  helped-woman
  helped-man
  total-helped
  raster-dataset
  raster-minimum
  raster-maximum
  init-count-needys
  init-female-needys
  init-male-needys
]

breed [ helpers helper ]
breed [ needys needy ]

to setup-turtles
  set-default-shape turtles "person"
  create-turtles population [
    setxy random-xcor random-ycor
    set color white
  ]
end

to setup
  ca
  setup-turtles
  set radius 2
  setup-humans
  setup-scenario
  reset-ticks
end

to setup-map
  ; Configure file paths of dataset
  let raster-path "UPLB_LowerCampus/uplb_lowercampus_3m.asc"

  ; Load Dataset
  set raster-dataset gis:load-dataset raster-path

  ; set-world-envelope maps the GIS coordinates with the NetLogo world coordinates
  ; envelope-union-of takes the union (duh) of all the envelopes/extents of the datasets
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of raster-dataset) )

   ; Visualize Raster

    ; Prepare max and min values for color mapping
    set raster-minimum gis:minimum-of raster-dataset
    set raster-maximum gis:maximum-of raster-dataset

    ; Apply the loaded raster to the patches
    gis:apply-raster raster-dataset patch-input

    ; Modify the colors based on user input

    ask patches[

    ; This is a hack to prevent non-numeric (NoData) values from being visualized,
    ; Get rid of this line and you'll suffer
    if (patch-input <= 0) or (patch-input >= 0)

       [

         set pcolor scale-color raster-color-picker patch-input raster-minimum raster-maximum

        ]

    ]

end

to setup-humans
  ask turtles [
    set age random (70) + 10
  ]
  let number-of-needys 0
  ask n-of (needy-percentage * population) turtles [
    set breed needys
    set color yellow
    set helped? false
    set gender "male"
    set age random (70) + 5
  ]
  set number-of-needys count turtles with [breed = needys]
  set init-count-needys number-of-needys
  ask n-of (needy-women-percentage * number-of-needys) turtles with [breed = needys] [
    set gender "female"
  ]
  set init-male-needys count needys with [gender = "male"]
  set init-female-needys count needys with [gender = "female"]
  ask turtles with [ breed != needys ] [
    set breed helpers
  ]
  let number-of-helpers 0
  set number-of-helpers count turtles with [breed = helpers]
  ask n-of ( women-percentage * number-of-helpers ) turtles with [breed = helpers] [
    set gender "female"
    set color pink
    let multiplier random (5) + 1
    set help-capacity 1 * (multiplier * .1)
  ]
  ask turtles with [ gender != "female" and breed = helpers] [
    set gender "male"
    set color blue
    let multiplier random (5) + 1
    set help-capacity 1 * (multiplier * .1)
  ]
  ask turtles with [ age <= 15  and breed = helpers] [
    set help-capacity 0
  ]
  ask turtles with [ breed = helpers ] [
    set helping? false
    set has-helped? false
    set target nobody
    connect
  ]
end

to setup-scenario
  ask turtles with [ breed = needys ] [
    set scenario random (3) + 1
    if scenario = 1 [
      set scenario "fainting"
    ]
    if scenario = 2 [
      set scenario "carrying"
    ]
    if scenario = 3 [
      set scenario "accident"
    ]
    set health-condition? random (2) + 1
    if health-condition? = 1 [
      set health-condition? true
    ]
    if health-condition? = 2 [
      set health-condition? false
    ]
  ]

end

to connect
  ask other turtles with [ breed = helpers ] in-radius radius [
    create-link-with myself [ tie ] ; so that they will move together
  ]
end

to go
  if nature = "static" [
    ask turtles with [ breed = helpers ] [
      move
    ]
  ]
  if nature = "moving" [
    ask helpers [
      move
    ]
    ask needys with [ scenario = "carrying" and helped? = false] [
      move
    ]

  ]
  ask turtles with [breed = helpers ] [
    help
  ]
  ask turtles with [breed = helpers ] [
    unhelp
  ]
  if total-helped = init-count-needys or ticks > 960[
    stop
  ]
  tick
end

to move
  rt random-float 360
  fd 1
end


to help
  let potential-target one-of (turtles-at -1 0) with [breed = needys and helped? = false]
  let gender? [gender] of self
  let helping-probability help-capacity - cost-of-helping
  ; check the attributes and situation of the NEEDY
  if potential-target != nobody [
    let genderTarget [gender] of potential-target
    let ageTarget [age] of potential-target
    let healthTarget [health-condition?] of potential-target
    let scenarioTarget [scenario] of potential-target
    if genderTarget = "female" [
      set helping-probability helping-probability + .20
    ]
    if ageTarget < 16[
      set helping-probability helping-probability + .20
    ]
    if genderTarget = "male" [
      set helping-probability helping-probability - .20
    ]
    if healthTarget = true [
      set helping-probability helping-probability + .20
    ]
    if ageTarget > 50 [
      set helping-probability helping-probability + .20
    ]
    if scenarioTarget = "carrying" and genderTarget = "male" and ageTarget < 50 [
      set helping-probability helping-probability - .20
    ]
    if scenarioTarget = "carrying"[
      set helping-probability helping-probability + .10
    ]
    if scenarioTarget = "carrying" and genderTarget = "female"[
      set helping-probability helping-probability + .15
    ]
    if scenarioTarget = "fainting"[
      set helping-probability helping-probability + .15
    ]
    if scenarioTarget = "fainting" and genderTarget = "female"[
      set helping-probability helping-probability + .25
    ]
    if scenarioTarget = "accident" and gender? = "male"[
      set helping-probability helping-probability + .30
    ]
    if scenarioTarget = "accident"[
      set helping-probability helping-probability + .20
    ]
  ]
  ; check the attribute and group of HELPER
  if gender? = "female" [
    set helping-probability helping-probability + .20
  ]
  if age < 16 [
    set helping-probability helping-probability - .20
  ]
  if age >= 20 and age <= 35 [
    set helping-probability helping-probability + .20
  ]
  if age > 35 [
    set helping-probability helping-probability - .20
  ]
  if count ([link-neighbors] of self) = 1 [
    set helping-probability helping-probability - .10
  ]
  if count ([link-neighbors] of self) = 2 [
    set helping-probability helping-probability - .15
  ]
  if count ([link-neighbors] of self) > 3 [
    set helping-probability helping-probability - .20
  ]
  ; actual helping
  if helping-probability >= .70 [
    if potential-target != nobody [
      set target potential-target
      face target
      if distance target > 0 [
        move-to target
      ]
      if distance target = 0 [
        set helping? true
        move-to patch-here
        ask target [move-to patch-here]
        set pcolor green
        set has-helped? true
        ask target [ set helped? true ]
        set total-helped total-helped + 1
        ask (patch-at -1 0) [ set pcolor green ]
        if gender? = "female" [
          set help-from-woman? help-from-woman? + 1
        ]
        if gender? = "male" [
          set help-from-man? help-from-man? + 1
        ]
        let genderTarget [gender] of target
        if genderTarget = "female" [
          set helped-woman helped-woman + 1
        ]
        if genderTarget = "male" [
          set helped-man helped-man + 1
        ]
        ask target [ set color brown ]
      ]
    ]
  ]
end

to unhelp
  if helping? [
   set helping? false
   set pcolor black
   ask (patch-at -1 0) [ set pcolor black ]
   set target nobody
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
224
83
709
569
-1
-1
11.63415
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

SLIDER
12
204
209
237
needy-percentage
needy-percentage
0
1
0.2
.05
1
NIL
HORIZONTAL

SLIDER
12
159
209
192
population
population
10
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
29
15
102
48
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
119
15
189
48
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
10
101
209
146
nature
nature
"moving" "static"
0

SLIDER
13
248
210
281
women-percentage
women-percentage
0
1
0.5
.05
1
NIL
HORIZONTAL

SLIDER
14
335
210
368
cost-of-helping
cost-of-helping
0
1
0.0
.1
1
NIL
HORIZONTAL

PLOT
773
19
1044
169
Gender of Helpers
Time
Frequency
0.0
10.0
0.0
100.0
true
true
"set-plot-y-range 0 80" ""
PENS
"Men" 1.0 0 -13345367 true "" "plot help-from-man?"
"Women" 1.0 0 -2064490 true "" "plot help-from-woman?"

PLOT
772
199
1046
349
Age
Age
Helper
0.0
10.0
0.0
50.0
true
true
"set-plot-y-range 0 15" ""
PENS
"count" 1.0 1 -13840069 true "" "set-histogram-num-bars 6\nhistogram [ age ] of helpers with [ has-helped? = true ] \n"
"ave-age" 1.0 0 -7500403 true "" "let age-list [ age ] of helpers\nlet min-age round (min age-list)\nlet max-age round (max age-list)\nifelse min-age < max-age \n  [ set-plot-x-range min-age max-age ]\n  [ set-plot-x-range min-age (min-age + 1) ]\n\n\n;; draw gray line in center of distribution\nplot-pen-reset\nlet ave-age mean age-list\nplotxy ave-age 0\nplotxy ave-age 15"

MONITOR
1055
74
1173
119
Women
count helpers with [ gender = \"female\" ]
17
1
11

MONITOR
1054
20
1174
65
Men
count helpers with [ gender = \"male\" ]
17
1
11

MONITOR
1055
254
1168
299
20 - 35 yrs. old
count helpers with [ age >= 20 and age <= 35 ]
17
1
11

MONITOR
1054
199
1167
244
10 - 19 yrs. old
count helpers with [ age >= 10 and age < 20 ]
17
1
11

MONITOR
1055
306
1169
351
36 and above
count helpers with [ age > 35 ]
17
1
11

PLOT
1203
20
1483
170
Helped Gender
Time
Frequency
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Men" 1.0 0 -13345367 true "" "plot helped-man"
"Women" 1.0 0 -2064490 true "" "plot helped-woman"

MONITOR
1490
70
1609
115
Women
count needys with [gender = \"female\"]
17
1
11

MONITOR
1490
20
1609
65
Men
count needys with [gender = \"male\"]
17
1
11

PLOT
1203
200
1485
350
Age of Helped Needy
Age
Needy
0.0
10.0
0.0
10.0
true
true
"set-plot-y-range 0 5" ""
PENS
"count" 1.0 1 -13840069 true "" "set-histogram-num-bars 6\nhistogram [ age ] of needys with [ helped? = true ]"
"ave-age" 1.0 0 -16777216 true "" "let age-list [ age ] of needys\nlet min-age round (min age-list)\nlet max-age round (max age-list)\nifelse min-age < max-age \n  [ set-plot-x-range min-age max-age ]\n  [ set-plot-x-range min-age (min-age + 1) ]\n\n\n;; draw gray line in center of distribution\nplot-pen-reset\nlet ave-age mean age-list\nplotxy ave-age 0\nplotxy ave-age 15"

MONITOR
1497
202
1602
247
5-16 yrs. old
count needys with [age < 16]
17
1
11

MONITOR
1497
255
1602
300
17-50 yrs.old
count needys with [age > 17 and age < 50]
17
1
11

MONITOR
1498
307
1603
352
50 and above
count needys with [ age > 50 ]
17
1
11

INPUTBOX
15
387
210
447
raster-color-picker
66.0
1
0
Color

BUTTON
30
60
189
93
NIL
setup-map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
12
289
210
322
needy-women-percentage
needy-women-percentage
0
1
0.45
.05
1
NIL
HORIZONTAL

MONITOR
548
22
701
67
NIL
total-helped
17
1
11

MONITOR
389
22
528
67
count needys
init-count-needys
17
1
11

MONITOR
234
22
369
67
count helpers
count turtles with [ breed = helpers ]
17
1
11

@#$#@#$#@
## WHAT IS IT?

It models helping in a university setting where different people in different social statuses can be found. As studied by several social scientist like Delamater and Myers (2011) and as discussed in SOC 130 class in UPLB under Prof. Shiela May Julianda, gender and age play big roles in helping. 

## HOW IT WORKS

1. Currently, we randomly spawn the turtles in the world. Links are formed if the turtles are within radius of 2 from each of other turtles. If the turtles are linked together, they will be tied so that they will move at a direction together.
2. The turtles are divided into two breeds: helpers and needys. Helpers will roam around in the world and will help the needys if they can (as determined by their helping capacity and helping probability).
3. Each helpers will look for its potential target needy and will calculate their own helping probability using equation: helping-pobability = help-capacity - cost-of-helping
The helping probability will be further computed by looking at the helper's attributes and the needy's attribute. Currently, each turtle will have a random help-capacity from 0.1 - 0.5. The factors that will be checked from the needy side are: age, gender, health-condition (true if has, false if doesn't have) and the scenario (fainting, carrying, or accident). On the other hand, the factors that will be checked from the helper side are: age, gender, and the number of links connected to it (the number of people in a group).
==================================================
Ex.
cost-of-helping: .2
helper:
age: 15
gender: male
count link neighbors: 2
helping-capacity: .3 (randomized)
needy (target):
age: 55
gender: female
scenario: fainting
health-condition?: true
==================================================
Computation:
(initial) helping-probability = .3 - .2 = .1
// check attributes and situation of target needy
(further computation)
// add .2 because the gender of target is female
helping-probability = .1 + .2 = .3
// add .2 because the target has health-condition
helping-probability = .3 + .2 = .5
// add .2 because the age of target is > 50
helping-probability = .5 + .2 = .7
// add .2  because the scenario is fainting
// check attributes of helper
// deduct .2 because the age of helper is < 16
helping-probability = .5 + .2 = .5
// deduct .2 because the link of neighbors is 2
helping-probability = .5 - .2 = .3
=================================================
4. Helping probability will be checked, and if it is greater than .70, it will help, else not. If can help, the needy and the helper will move at the same patch (as if the helper is helping the needy) for a while and the patch beside them will become green as an indicator that helping is happening. The count of help from male and female is updated and the count for helpers who received helped is also obtained. The distribution of age from both helpers who helped and needys who received help are also being monitored. 


## HOW TO USE IT

SETUP button --- sets up the model by creating the agents.
GO button --- runs the model
Nature chooser --- sets the nature of the helpers, if they will move together with the helpers or if they will stay on their place.
Setup-map button--- sets up the UPLB lower campus map
Color-picker input --- sets the color of the buildings in the map

There are 5 sliders for controlling environmental variables:
population slider --- this will determine the number of turtles in the environment
needy-percentage slider --- this will determine how many of the population will become needy
women-percentage slider --- this will determine how many of the population (that are not needy) will have a gender "female"
needy-women-percentage slider --- this will determine how many of the needys will have a gender "female"
cost-of-helping slider --- this will determine the cost of helping that will be used in the computation of helping probability as stated above.
 
## THINGS TO TRY

1. Try to setup the world initializing cost-of-helping 0 and set women-percentage a little lower than the number of males say .45. Do the number of female helpers still dominates the other gender?

2. Now, try to set needy-women-percentage to .45 or a little more lower, do the number of female needys who received help still dominates the other gender?

3. Can you find slider values that maximize the advantage of the male agents helping?

4.  Try running BehaviorSpace on this model to explore the model's behavior under a range of initial conditions.

## EXTENDING THE MODEL

The model can be extended in a number of interesting directions, including adding new environmental variables, adding different types of agents. This model has a feature for map use but the movements of turtle does not follow it yet.

This model does not address the behaviors of individuals, only the relative weights of genetic traits.

## NETLOGO FEATURES

This model uses patches as its basic agents. Can you design an "equivalent" model using turtles?  How would the model dynamics be affected?

## RELATED MODELS

Altruism, Cooperation

## CREDITS AND REFERENCES
DeLamater, J.D. & Myers, D.J. (2011). Social Psychology. Wadsworth, 221 - 243.
Julianda, S.M.(2017) SOC 130 class.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Nicolas, Mark Jay A. (2018)  NetLogo Helping Model.  

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.


<!-- 2018 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment 1 static" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>help-from-man?</metric>
    <metric>help-from-woman?</metric>
    <metric>helped-man</metric>
    <metric>helped-woman</metric>
    <steppedValueSet variable="women-percentage" first="0.1" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="needy-percentage">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nature">
      <value value="&quot;static&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="cost-of-helping" first="0" step="0.1" last="0.5"/>
    <steppedValueSet variable="needy-women-percentage" first="0.1" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="population">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 1 moving" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>help-from-man?</metric>
    <metric>help-from-woman?</metric>
    <metric>helped-man</metric>
    <metric>helped-woman</metric>
    <steppedValueSet variable="women-percentage" first="0.1" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="needy-percentage">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nature">
      <value value="&quot;moving&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="cost-of-helping" first="0" step="0.1" last="0.5"/>
    <steppedValueSet variable="needy-women-percentage" first="0.1" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="population">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
