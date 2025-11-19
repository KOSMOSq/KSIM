breed [sheep a-sheep]
breed [shepherds shepherd]

globals
[
  sheepless-neighborhoods
  herding-efficiency
]

patches-own [ sheep-nearby ]

shepherds-own
[
  carried-sheep    ;; вівця, яку несе пастух
  found-herd?      ;; чи знайшов стадо
  team             ;; 0 - Червоні, 1 - Сині
  energy           ;; рівень енергії (втома)
  resting?         ;; чи відпочиває пастух зараз
]

sheep-own [ team ] ;; 0 - Червоні, 1 - Сині

;; SETUP

to setup
  clear-all
  
  set-default-shape sheep "sheep"
  set-default-shape shepherds "person"
  
  ask patches
    [ set pcolor green + (random-float 0.8) - 0.4]
  
  create-sheep num-sheep
  [ 
    set size 1.5
    setxy random-xcor random-ycor
    set team random 2
    ifelse team = 0 [ set color red ] [ set color blue ]
  ]
    
  create-shepherds num-shepherds
  [ 
    set size 1.5
    set carried-sheep nobody
    set found-herd? false
    setxy random-xcor random-ycor
    
    set energy 20 + random 40
    set resting? false
    
    set team random 2
    ifelse team = 0 [ set color red ] [ set color blue ]
  ]
    
  reset-ticks
end

to update-sheep-counts
  ask patches
    [ set sheep-nearby (sum [count sheep-here] of neighbors) ]
  set sheepless-neighborhoods (count patches with [sheep-nearby = 0])
end

to calculate-herding-efficiency
  let total-patches count patches with [not any? sheep-here]
  if total-patches = 0 [ set total-patches 1 ]
  set herding-efficiency (sheepless-neighborhoods / total-patches) * 100
end


to go
  ask shepherds
  [ 
    set label floor energy

    ;; Логіка втоми
    
    if energy < 5 [
      set resting? true
    ]

    if resting? [
      set color gray
      set energy energy + 10
      
      if energy >= 50 [
        set resting? false
        
        ;; Відновлення кольору після відпочинку (жовтий, якщо несе овцю)
        ifelse carried-sheep != nobody
          [ set color yellow ]
          [ ifelse team = 0 [ set color red ] [ set color blue ] ]
      ]
      
      stop
    ]

    ;; Страховка кольору для активного стану
    if color = gray [
       ifelse carried-sheep != nobody
          [ set color yellow ]
          [ ifelse team = 0 [ set color red ] [ set color blue ] ]
    ]

    ;; Основна поведінка
    ifelse carried-sheep = nobody
      [ search-for-sheep ]
      [ ifelse found-herd?
          [ find-empty-spot ]
          [ find-new-herd ] ]
          
    wiggle
    fd 1
    
    ;; Витрата енергії
    ifelse carried-sheep = nobody 
      [ set energy energy - 1 ]
      [ set energy energy - 3 ]
    
    if carried-sheep != nobody
    [ ask carried-sheep [ move-to myself ] ] 
  ]
  
  ask sheep with [not hidden?]
  [ wiggle
    fd sheep-speed ]
    
  update-sheep-counts
  calculate-herding-efficiency
  
  tick
end


to wiggle
  rt random 50 - random 50
end


to search-for-sheep
  ;; Логіка крадіжки: беремо вівцю, якщо вона своя АБО якщо allow-stealing? = true
  set carried-sheep one-of sheep-here with [
    not hidden? and (team = [team] of myself or allow-stealing?)
  ]
  
  if (carried-sheep != nobody)
  [ 
    ask carried-sheep [ hide-turtle ]
    set color yellow
    fd 1
  ]
end


to find-new-herd
  if any? sheep-here with [not hidden?]
    [ set found-herd? true ]
end


to find-empty-spot
  if all? sheep-here [hidden?]
  [
    ask carried-sheep
    [ 
      show-turtle
      ;; Асиміляція: вівця змінює команду на команду пастуха
      set team [team] of myself
      ifelse team = 0 [ set color red ] [ set color blue ]
      rt random 360
      fd 1 
    ]
      
    ;; Пастух скинув вівцю, повертається до кольору команди
    ifelse team = 0 [ set color red ] [ set color blue ]
      
    set carried-sheep nobody
    set found-herd? false
    rt random 360
    fd 20
  ]
end
