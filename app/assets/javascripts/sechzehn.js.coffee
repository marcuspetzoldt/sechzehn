# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


$(document).on('focus', 'form#form_signin input', () ->
  $('div.alert').fadeOut(500, () ->
    $(this).remove()
  )
)

$(document).ready(() ->
  window.___gcfg = {lang: 'de'};
  window.chatDelta = Math.floor(Math.random()*5)
  showDice(true)
  if $('input#words').length > 0
    sync()
  else
    # Sechzehn auf Homepage hervorheben
    canvas = $('canvas#field')
    context = canvas[0].getContext('2d')
    letter = canvas.attr('data-letters')
    for y in [1..2]
      for x in [0..3]
          drawLetter(context, x, y, letter[y*4+x], '#ffff00')
)

$(document).on('mousedown touchstart', 'canvas#field', (event) ->
  event.preventDefault()
  if $('input#words:disabled').length == 0
    x = Math.floor((event.clientX - $(this).offset().left) / 70)
    y = Math.floor((event.clientY - $(this).offset().top) / 70)
    context = this.getContext('2d')
    letter = $(this).attr('data-letters')[y*4+x]
    $('input#words').val($('input#words').val() + letter)
    drawLetter(context, x, y, letter, '#dfdf00')
    window.mouseIn = new Array()
    window.mouseIn.push([x, y])
    window.mouseDown = true
  return true
)

$(document).on('mousemove touchmove', 'canvas#field', (event) ->
  event.preventDefault()
  if window.mouseDown
    if event.originalEvent.touches
      dX = event.originalEvent.touches[0].clientX - $(this).offset().left
      dY = event.originalEvent.touches[0].clientY - $(this).offset().top
    else
      dX = event.clientX - $(this).offset().left
      dY = event.clientY - $(this).offset().top
    if Math.abs(dX % 70) > 16 and Math.abs(dY %70) > 16
      x = Math.floor(dX / 70)
      y = Math.floor(dY / 70)
      unless x == window.mouseIn[window.mouseIn.length-1][0] and y == window.mouseIn[window.mouseIn.length-1][1]
        context = this.getContext('2d')
        letters = $(this).attr('data-letters')
        truncate = false
        word = $('input#words').val()
        for coord, index in window.mouseIn
          if coord[0] == x and coord[1] == y
            truncate = true
            break
        if truncate
          window.mouseIn = window.mouseIn[0..index]
          word = word[0..index]
          $('input#words').val(word)
        else
          window.mouseIn.push([x,y])
          $('input#words').val(word + letters[y*4+x])
        showDice(true)
        if window.mouseIn.length > 1
          for i in [1..window.mouseIn.length-1]
            drawLine(context, window.mouseIn[i-1], window.mouseIn[i])
        if window.mouseIn.length > 1
          for i in [0..window.mouseIn.length-2]
            drawLetter(context, window.mouseIn[i][0], window.mouseIn[i][1], letters[window.mouseIn[i][1]*4+window.mouseIn[i][0]], '#ffff00')

        if window.mouseIn.length > 0
          drawLetter(context, window.mouseIn[window.mouseIn.length-1][0], window.mouseIn[window.mouseIn.length-1][1], letters[window.mouseIn[window.mouseIn.length-1][1]*4+window.mouseIn[window.mouseIn.length-1][0]], '#dfdf00')
        $('input#words').val($('input#words').val() + $('div#'+id).text().trim())
  return true
)

$(document).on('mouseup touchend', 'body', () ->
  if window.mouseDown
    w = $('input#words').val().toLowerCase()
    if w.length > 2
      if $('span#word_' + w).length == 0
        $('div#guesses').prepend(' <span id="word_' + w + '">' + w + '</span>')
        $.ajax({ url: '/guess', data: 'words=' + w })
    $('input#words').val('')
    window.mouseDown = 0
    showDice(true)
  return true
)

$(document).on('keydown', 'input#words', (event) ->
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

  canvas = $("canvas#field")
  letters = canvas.attr("data-letters")
  context = canvas[0].getContext("2d")
  f = [
    [[0, letters[0]], [0, letters[1]], [0, letters[2]], [0, letters[3]]],
    [[0, letters[4]], [0, letters[5]], [0, letters[6]], [0, letters[7]]],
    [[0, letters[8]], [0, letters[9]], [0, letters[10]], [0, letters[11]]],
    [[0, letters[12]], [0, letters[13]], [0, letters[14]], [0, letters[15]]]
  ]
  for x in [0..3]
    for y in [0..3]
      conditionMet = snake f, withoutQu(w.toUpperCase()), x, y
      break if conditionMet
    break if conditionMet

  window.snake = false
  showDice(true)
  snakeCoords = new Array()
  for i in [0..w.length-1]
    snakeCoords.push([-1, -1])
  for x in [0..3]
    for y in [0..3]
      if f[y][x][0] > 0
        window.snake = true
        snakeCoords[f[y][x][0]-1] = [x, y]
  if w.length > 1
    for i in [1..w.length-1]
      drawLine(context, snakeCoords[i-1], snakeCoords[i])
  if w.length > 1
    for i in [1..w.length-1]
      drawLetter(context, snakeCoords[i][0], snakeCoords[i][1], f[snakeCoords[i][1]][snakeCoords[i][0]][1], '#ffff00')

  if w.length > 0
    drawLetter(context, snakeCoords[0][0], snakeCoords[0][1], f[snakeCoords[0][1]][snakeCoords[0][0]][1], '#dfdf00')
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
    field[y][x][0] = word.length
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


showDice = (enable) ->
  canvas = $("canvas#field")
  context = canvas[0].getContext("2d")
  letters = canvas.attr('data-letters')
  context.beginPath()
  if enable
    context.fillStyle = '#ffffff'
  else
    context.fillStyle = '#eeeeee'
  context.fillRect(0, 0, 280, 280)
  context.lineWidth = 1
  for i in [1..3]
    context.moveTo(i*70, 0)
    context.lineTo(i*70, 280)
    context.moveTo(0, i*70)
    context.lineTo(280, i*70)
  context.strokeStyle = "#000"
  context.stroke()
  context.font = '600 300% sans-serif'
  context.textAlign = 'center'
  context.textBaseline = 'middle'
  if enable
    context.fillStyle = '#000000'
  else
    context.fillStyle = '#999999'
  for i in [0..3]
    for j in [0..3]
      context.fillText(letters[j*4+i], 35+i*70, 35+j*70 )
  context.closePath()

drawLetter = (context, x, y, letter, color) ->
  context.beginPath()
  context.strokeStyle = '#aaa'
  context.lineWidth = 4
  context.arc(x*70+35, y*70+35, 28, 28, 0, 2*Math.PI, false)
  context.stroke()
  context.closePath()
  context.beginPath()
  context.fillStyle = color
  if color == '#ffffff'
    context.fillRect(x*70+1, y*70+1, 68, 68)
  else
    context.arc(x*70+35, y*70+35, 27, 27, 0, 2*Math.PI, false)
  context.fill()
  context.closePath()
  context.beginPath()
  context.font = '600 300% sans-serif'
  context.textAlign = 'center'
  context.textBaseline = 'middle'
  context.fillStyle = '#000000'
  context.fillText(letter, 35+x*70, 35+y*70 )
  context.closePath()

drawLine = (context, startPoint, endPoint) ->
  if startPoint
    context.lineWidth = 6
    context.strokeStyle = '#aaa'
    context.beginPath()
    context.moveTo(startPoint[0]*70+35, startPoint[1]*70+35)
    context.lineTo(endPoint[0]*70+35, endPoint[1]*70+35)
    context.stroke()
    context.closePath()

clock = () ->
  t = 0
  window.gameTimer--
  if (window.gameTimer <= 0)
    window.gameMode = 'sync'
    $('input#words').val('Spiel auswerten ...')
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
          $('input#words').val('Spiel startet in ...')
          disableGame()
          getSolution()
      else
        if (window.gameMode != 'limbo')
          window.gameMode = 'limbo'
          $('input#words').val('Spiel auswerten ...')
          disableGame()
  $('span#timer').html( ((t/60)|0).toString() + ':' + ('0' + (t%60).toString())[-2..])
  if (window.gameTimer % 5 == window.chatDelta)
    $.get('/chat/messages')
  return true

sync = () ->
  clearInterval(window.gameInterval) if window.gameInterval
  $.get('/sync', null, (data) ->
    if data == 'maintenance'
      window.gameTimer = 210
      window.maintenance = true
    else
      window.gameTimer = parseInt(data)
      window.maintenance = false
    window.gameInterval = setInterval(clock, 1000)
  )

getSolution = () ->
  $.get('/solution')

startGame = () ->
  if window.maintenance
    clearInterval(window.gameInterval) if window.gameInterval
    alert("Wartungsarbeiten - Sechzehn kann einige Minuten nicht gespielt werden.")
    window.Location.href='/'
    window.location.reload()
    return
  $('canvas#field').load('/new', null, (responseText, textStatus, XMLHttpRequest) ->
    if XMLHttpRequest.getResponseHeader('X-Refreshed') == '0'
      $('div#solution').html('')
      $('div#guesses').html('')
      $('td#cwords').html('0')
      $('td#cpoints').html('0')
    $("canvas#field").attr("data-letters", responseText)
    showDice(true)
    $('input#words')
      .removeAttr('disabled')
      .val('')
      .focus()
    getSolution()
  )

disableGame = () ->
  window.mouseDown = 0
  $('input#words').attr('disabled', 'disabled')
  showDice(false)

# Length hint
$(document).on('focus', 'input[maxlength]', () ->
  $(this).after('<span class="length-hint">' + $(this).val().length + '/' + $(this).attr('maxLength') + '</span>')
  $hint = $(this).next()
  $hint.css('margin-left', '-' + ($hint.width() + 15) + 'px')
)

$(document).on('blur', 'input[maxlength]', () ->
  $(this).next().remove()
)

$(document).on('keyup', 'input[maxlength]', () ->
  $hint = $(this).next()
  $hint.text($(this).val().length + '/' + $(this).attr('maxLength'))
  $hint.css('margin-left', '-' + ($hint.width() + 15) + 'px')
)

# Facebook like
((d, s, id) ->
  fjs = d.getElementsByTagName(s)[0]
  if d.getElementById(id)
    return
  js = d.createElement(s)
  js.id = id
  js.src = "//connect.facebook.net/de_DE/all.js#xfbml=1"
  fjs.parentNode.insertBefore(js, fjs))(document, 'script', 'facebook-jssdk')

# google +1
(() ->
  po = document.createElement('script')
  po.type = 'text/javascript'
  po.async = true
  po.src = 'https://apis.google.com/js/platform.js'
  s = document.getElementsByTagName('script')[0]
  s.parentNode.insertBefore(po, s))()

$(document).on('mousedown', 'img#kostenlos-browsergame', () ->
  if document.images
    (new Image()).src='http://www.kostenlos-browsergame.de/in.php?id=222'
  return true
)