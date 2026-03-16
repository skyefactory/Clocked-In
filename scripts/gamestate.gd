extends Node

enum States {
    MENU,
    KITCHEN,
    GAMEOVER
}
var current_state = null

var cash = 0
var rating = 0
var rating_points = 0
var unlocks = []
var current_day = 0