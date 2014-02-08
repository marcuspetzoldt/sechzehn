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

$(document).on('mousedown', 'div.letter', (event) ->
  event.preventDefault()
  if $('input#words:disabled').length == 0
    $('input#words').val($('input#words').val() + $(this).text().trim())
    $(this).css('background-color', '#dfdf00')
    window.mouseDown = 1
    window.mouseIn = this.id
  return true
)

$(document).on('mousemove', 'div.letter', (event) ->
  event.preventDefault()
  if window.mouseDown
    if this.id != window.mouseIn[-3..]
      divX = event.clientX - $(this).offset().left
      divY = event.clientY - $(this).offset().top
      if divX > 10 and divX < 60 and divY > 10 and divY < 60
        while window.mouseIn.indexOf(this.id) > -1
          $('div#'+window.mouseIn[-3..]).css('background-color', '#ffffff')
          window.mouseIn = window.mouseIn[0..-4]
          $('input#words').val($('input#words').val()[..-2])
        $('div#'+window.mouseIn[-3..]).css('background-color', '#ffff00')
        window.mouseIn = window.mouseIn + this.id
        $(this).css('background-color', '#dfdf00')
        $('input#words').val($('input#words').val() + $(this).text().trim())
  return true
)

$(document).on('mouseup', 'body', () ->
  if window.mouseDown
    w = $('input#words').val().toLowerCase()
    if w.length > 2
      if $('span#word_' + w).length == 0
        $('div#guesses').prepend(' <span id="word_' + w + '">' + w + '</span>')
        $.ajax({ url: '/guess', data: 'words=' + w })
    $('input#words').val('')
    window.mouseDown = 0
    $('div.letter').css('background-color', '#ffffff')
  return true
)

$(document).on('keypress', 'input#words', (event) ->
  if event.which == 8
    # Backspace
    w = this.value[0..-2]
  else
    w = this.value
    if event.which == 13
      if w.length > 2
        if $('span#word_' + w).length == 0
          if window.snake
            $('div#guesses').prepend(' <span id="word_' + w + '">' + w + '</span>')
            $.ajax({ url: '/guess', data: 'words=' + w })
          else
            $('div#guesses').prepend(' <span id="word_' + w + '" style="color:red">' + w + '</span>')
        $('input#words').val('')
        w = ''
    else
      if event.which > 0
        w = w + String.fromCharCode(event.which)

  f = [
    [[0, $('div#l0').text().trim()[0]], [0, $('div#l1').text().trim()[0]], [0, $('div#l2').text().trim()[0]], [0, $('div#l3').text().trim()[0]]],
    [[0, $('div#l4').text().trim()[0]], [0, $('div#l5').text().trim()[0]], [0, $('div#l6').text().trim()[0]], [0, $('div#l7').text().trim()[0]]],
    [[0, $('div#l8').text().trim()[0]], [0, $('div#l9').text().trim()[0]], [0, $('div#l10').text().trim()[0]], [0, $('div#l11').text().trim()[0]]],
    [[0, $('div#l12').text().trim()[0]], [0, $('div#l13').text().trim()[0]], [0, $('div#l14').text().trim()[0]], [0, $('div#l15').text().trim()[0]]]
  ]
  for x in [0..3]
    for y in [0..3]
      conditionMet = snake f, withoutQu(w.toUpperCase()), x, y
      break if conditionMet
    break if conditionMet

  window.snake = false
  for x in [0..3]
    for y in [0..3]
      switch f[y][x][0]
        when 1
          window.snake = true
          $('div#l' + (x + y*4)).css('background-color', '#ffffa0')
        when 2
          window.snake = true
          $('div#l' + (x + y*4)).css('background-color', '#dfdf00')
        else $('div#l' + (x + y*4)).css('background-color', '#ffffff')

  return true
)

withoutQu = (word) ->
  return word.replace('QU', 'Q')

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
    window.gameMode = 'sync'
    disableGame()
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
          window.gameMode = 'score'
          disableGame()
          getSolution()
          $('input#words').val('')
      else
        if (window.gameMode != 'limbo')
          window.gameMode = 'limbo'
          disableGame()
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
  $('div#field').load('/new', null, (responseText, textStatus, XMLHttpRequest) ->
    if XMLHttpRequest.getResponseHeader('X-Refreshed') == '0'
      $('div#solution').html('')
      $('div#guesses').html('')
      $('div#solutionheader').hide()
      $('td#cwords').html('0')
      $('td#cpoints').html('0')
    $('input#words').removeAttr('disabled')
    $('input#words').focus()
  )

disableGame = () ->
  $('input#words').attr('disabled', 'disabled')
  $('input#words').val('Spiel auswerten ...')
  $('div.letter').css({'background-color' : '#eeeeee', 'color' : '#999999'})
