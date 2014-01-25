# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


$(document).on('focus', 'form#signin input', () ->
  $('div.alert').fadeOut(500, () ->
    $(this).remove()
  )
)

$(document).ready(() ->
  sync()
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

$(document).on('submit', 'guess', () ->
  for i in [0..15]
    $('div#' + i).css('background-color', 'white')
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
  t = 0
  window.gameTimer--
  if (window.gameTimer <= 0)
    $('input#words').attr('disabled', 'disabled')
    $('input#words').val('Spiel auswerten ...')
    sync()
  else
    if (window.gameTimer <= 180)
      t = window.gameTimer
      if (window.gameMode != 'play')
        window.gameMode = 'play'
        startGame()
    else
      if (window.gameTimer <= 210)
        t = window.gameTimer - 180
        if (window.gameMode != 'score')
          $('input#words').val('')
          window.gameMode = 'score'
          getSolution()
      else
        if (window.gameMode != 'limbo')
          window.gameMode = 'limbo'
          $('input#words').attr('disabled', 'disabled')
          $('input#words').val('neues Spiel erzeugen ...')
  $('span#timer').html( ((t/60)|0).toString() + ':' + ('0' + (t%60).toString())[-2..])
  return true

sync = () ->
  clearInterval(window.gameInterval) if window.gameInterval
  $.get('/sync', null, (data) ->
    window.gameTimer = parseInt(data)
  )
  window.gameInterval = setInterval(clock, 1000)

getSolution = () ->
  $('input#words').attr('disabled', 'disabled')
  $('div#solutionheader').show()
  $.get('/solution')

startGame = () ->
  $.get('/new', null, (data) ->
    $('div#field').html(data)
  )
  $('input#words').removeAttr('disabled')
  $('input#words').focus()
  $('div#solution').html('')
  $('div#guesses').html('')
  $('div#solutionheader').hide()
  $('td#cwords').html('0')
  $('td#cpoints').html('0')
