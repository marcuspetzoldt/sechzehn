# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


theClock = 10
timerId = 0
$(document).ready(() ->
  $('input#words').focus()
  timerId = setInterval(clock, 1000)
)

$(document).on('keyup', 'input#words', () ->
  w = this.value
  f = [
    [[0, $('div#l0').text().trim()], [0, $('div#l1').text().trim()], [0, $('div#l2').text().trim()], [0, $('div#l3').text().trim()]],
    [[0, $('div#l4').text().trim()], [0, $('div#l5').text().trim()], [0, $('div#l6').text().trim()], [0, $('div#l7').text().trim()]],
    [[0, $('div#l8').text().trim()], [0, $('div#l9').text().trim()], [0, $('div#l10').text().trim()], [0, $('div#l11').text().trim()]],
    [[0, $('div#l12').text().trim()], [0, $('div#l13').text().trim()], [0, $('div#l14').text().trim()], [0, $('div#l15').text().trim()]]
  ]
  for x in [0..3]
    for y in [0..3]
      conditionMet = snake f, w.toUpperCase(), x, y
      break if conditionMet
    break if conditionMet

  for x in [0..3]
    for y in [0..3]
      switch f[y][x][0]
        when 1 then  $('div#l' + (x + y*4)).css('background-color', '#ffffa0')
        when 2 then  $('div#l' + (x + y*4)).css('background-color', '#dfdf00')
        else $('div#l' + (x + y*4)).css('background-color', '#ffffff')

)

snake = (field, word, x, y) ->

  # break if empty word
  return true unless word

  # break if out of bounds
  return false if x < 0
  return false if x > 3
  return false if y < 0
  return false if y > 3

  # break if already used
  return false if field[y][x][0] > 0

  if field[y][x][1] == word[0]
    field[y][x][0] = if word.length == 1 then 2 else 1
    for dx in [-1..1]
      for dy in [-1..1]
        if dx == 0 and dy == 0
          conditionMet = false
        else
          conditionMet = snake field, word[1..], x+dx, y+dy
        break if conditionMet
      break if conditionMet
    return true if conditionMet
    field[y][x][0] = 0
  return false

clock = () ->
  if theClock-- < 1
    clearTimeout(timerId)
    $.get('/solution')
  else
    $('div#timer').html(((theClock / 60)|0) + ':' + ('0' + (theClock % 60))[-2..])
  return true
