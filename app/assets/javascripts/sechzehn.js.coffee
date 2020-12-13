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
  showDice(true)

  myDataRef = new Firebase('https://luminous-inferno-1701.firebaseio.com/')
  myDataRef.on('child_changed', (snapshot, prevChildName) ->
    sys = snapshot.child('sys')
    name = snapshot.child('usr')
    text = snapshot.child('msg')
    resizable_chat = $('#resizable-chat')
    if sys.val() is 0
      resizable_chat
        .append('<div><span class="username">' + name.val() + '</span>' + text.val() + '</div>')
        .scrollTop(resizable_chat[0].scrollHeight)
    else
      resizable_chat
        .append('<div><em class="text-muted">' + name.val() + ' ' + text.val() + '<em></div>')
        .scrollTop(resizable_chat[0].scrollHeight)
      getLeaderboard()
  )
  if $('input#words').length > 0
    sync()
  else
    # Highlight SECHZEHN on homepage
    canvas = $('canvas#field')
    context = canvas[0].getContext('2d')
    letters = canvas.attr('data-letters')
    for y in [1..2]
      for x in [0..3]
        highlightLetter(context, x, y, letters[y*4+x])
)

$(document).on('mousedown touchstart', 'div.username', () ->
  $('span.guess').not('span.'+$(this).attr('data-uid')).hide()
)

$(document).on('mouseup touchend', 'div.username', () ->
  $('span.guess').show()
)

$(document).on('mousedown touchstart', 'span.guess', () ->
  guessed_word = $(this)
  $('div.username').each( () ->
    unless guessed_word.hasClass($(this).attr('data-uid'))
      $(this).hide()
  )
)

$(document).on('mouseup touchend', 'span.guess', () ->
  $('div.username').show()
)

$(document).on('submit', 'form#chat_form', (event) ->
  $('input#chat_chat').val('')
)

$(document).on('scroll', 'canvas#field', () ->
    event.preventDefault()
    return false
)

$(document).on('mousedown touchstart', 'canvas#field', (event) ->
  event.preventDefault()
  if $('input#words').length > 0 and $('input#words:disabled').length == 0
    x = 0
    y = 0
    rect = this.getBoundingClientRect()
    if event.originalEvent.touches
      x = Math.floor((event.originalEvent.touches[0].clientX - rect.left) / 70)
      y = Math.floor((event.originalEvent.touches[0].clientY - rect.top) / 70)
    else
      x = Math.floor((event.clientX - rect.left) / 70)
      y = Math.floor((event.clientY - rect.top) / 70)
    context = this.getContext('2d')
    letters = $(this).attr('data-letters')
    if letters[y*4+x] == 'Q'
      $('input#words').val('QU')
    else
      $('input#words').val(letters[y*4+x])
    window.snake = [[x, y]]
    window.mouseDown = true
    showDice(true)
    showSnake(context, letters)
  return true
)

$(document).on('mousemove touchmove', 'canvas#field', (event) ->
  event.preventDefault()
  if window.mouseDown
    dX = 0
    dY = 0
    rect = this.getBoundingClientRect()
    if event.originalEvent.touches
      dX = event.originalEvent.touches[0].clientX - rect.left
      dY = event.originalEvent.touches[0].clientY - rect.top
    else
      dX = event.clientX - rect.left
      dY = event.clientY - rect.top
    dXZone = Math.abs(dX % 70)
    dYZone = Math.abs(dY % 70)
    x = Math.floor(dX / 70)
    y = Math.floor(dY / 70)
    if Math.abs(x-window.snake[window.snake.length-1][0]) < 2 and Math.abs(y-window.snake[window.snake.length-1][1]) < 2
      if dXZone > 12 and dXZone < 58 and dYZone > 12 and dYZone < 58
        unless x == window.snake[window.snake.length-1][0] and y == window.snake[window.snake.length-1][1]
          letters = $(this).attr('data-letters')
          truncate = false
          backspace = false
          word = $('input#words').val()
          for coord, index in window.snake
            if coord[0] == x and coord[1] == y
              if index == window.snake.length-2
                backspace = true
              else
                truncate = true
              break
          unless truncate
            if backspace
              window.snake.pop()
              if word[word.length-2..-1] == 'QU'
                $('input#words').val(word[0..-3])
              else
                $('input#words').val(word[0..-2])
            else
              window.snake.push(new Array(x,y))
              if letters[y*4+x] == 'Q'
                $('input#words').val(word + 'QU')
              else
                $('input#words').val(word + letters[y*4+x])

            context = this.getContext('2d')
            showDice(true)
            showSnake(context, letters)
  return true
)

$(document).on('mouseup touchend', 'body', () ->
  if window.mouseDown
    w = $('input#words').val().toLowerCase()
    if w.length > 2
      if $('span#word_' + w).length == 0
        $('div#guesses').prepend(' <span id="word_' + w + '">' + w + '</span>')
        $.ajax(
          url: '/guess',
          type: 'POST',
          beforeSend: (xhr) -> xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')),
          success: (data, status) -> guessSuccess(data, status)
          data: 'words=' + w
        )
    $('input#words').val('')
    window.mouseDown = 0
    showDice(true)
  return true
)

$(document).on('keydown', 'input#words', (event) ->
  w = ''
  if event.which == 8
    # Backspace
    w = this.value[0..-2]
  else
    w = this.value
    if event.which == 13
      if w.length > 2
        if $('span#word_' + w.toLocaleLowerCase()).length == 0
          if window.snake.length > 0
            $('div#guesses').prepend(' <span id="word_' + w + '">' + w + '</span>')
            $.ajax(
              url: '/guess',
              type: 'POST',
              beforeSend: (xhr) -> xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')),
              data: 'words=' + w
              success: (data, status) -> guessSuccess(data, status)
            )
          else
            $('div#guesses').prepend(' <span id="word_' + w + '" style="color:red">' + w + '</span>')
        $('input#words').val('')
        w = ''
    else
      if event.which > 64 and event.which < 91
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
  window.snake = []
  for x in [0..3]
    for y in [0..3]
      conditionMet = snake f, withoutQu(w.toUpperCase()), x, y
      break if conditionMet
    break if conditionMet

  showDice(true)
  showSnake(context, letters)
  return true
)

withoutQu = (word) ->
  return word.replace('QU', 'Q')

guessSuccess = (data, status) ->
  if data.success
    span = $('span#word_' + data.word)
    if data.points > 0
      span.append(':' + data.points)
      span.css('font-size',  (100 + (data.points-1)*4).toString() + '%')
    else
      span.css('color', 'red')
    $('td#cwords').html(data.cwords)
    $('td#cpoints').html(data.cpoints)
    window.gameTimer = parseInt(data.time)
  else
    alert('Das Session-Cookie ist nicht mehr vorhanden, oder kann nicht gelesen werden.')
    window.Location.href='/'
    window.location.reload()

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
    window.snake.push(new Array(x, y))
    field[y][x][0] = 1 #word.length
    for dx in [-1..1]
      for dy in [-1..1]
        conditionMet = false
        unless dx == 0 and dy == 0
          conditionMet = snake field, word[1..], x+dx, y+dy
        break if conditionMet
      break if conditionMet
    return true if conditionMet
    window.snake.pop()
    field[y][x][0] = 0
  return false


showDice = (enable) ->
  i = 0
  canvas = $("canvas#field")
  context = canvas[0].getContext("2d")
  letters = canvas.attr('data-letters')
  context.clearRect(0, 0, 280, 280)
  context.beginPath()
  for i in [1..3]
    context.moveTo(i*70, 0)
    context.lineTo(i*70, 280)
    context.moveTo(0, i*70)
    context.lineTo(280, i*70)
  context.lineWidth = 1
  context.strokeStyle = "#000"
  context.stroke()
  context.closePath()
  context.beginPath()
  context.font = 'normal normal 600 42px sans-serif'
  context.textAlign = 'center'
  context.textBaseline = 'middle'
  if enable
    context.fillStyle = '#000000'
  else
    context.fillStyle = '#999999'
  for i in [0..3]
    for j in [0..3]
      letter = letters[j*4+i]
      if letter == 'Q'
        letter = 'Qu'
      context.fillText(letter, 35+i*70, 35+j*70 )
  context.closePath()

highlightLetter = (context, x, y, letter) ->
  context.beginPath()
  context.arc(x*70+35, y*70+35, 28, 0, 2*Math.PI, false)
  context.fillStyle = "#ffff00"
  context.fill()
  context.strokeStyle = '#aaaaaa'
  context.lineWidth = 4
  context.stroke()
  context.closePath()
  context.beginPath()
  context.font = 'normal normal 600 42px sans-serif'
  context.textAlign = 'center'
  context.textBaseline = 'middle'
  context.fillStyle = '#000000'
  if letter == 'Q'
    letter = 'Qu'
  context.fillText(letter, 35+x*70, 35+y*70 )
  context.closePath()

showSnake = (context, letters) ->
  i = 0
  if window.snake.length > 1
    # Junctions
    context.beginPath()
    context.moveTo(window.snake[0][0]*70+35, window.snake[0][1]*70+35)
    for i in [1..window.snake.length-1]
      context.lineTo(window.snake[i][0]*70+35, window.snake[i][1]*70+35)
    context.lineWidth = 6
    context.strokeStyle = '#aaa'
    context.stroke()
    context.closePath()
    # Circles
    for i in [0..window.snake.length-2]
      context.beginPath()
      context.arc(window.snake[i][0]*70+35, window.snake[i][1]*70+35, 28, 0, 2*Math.PI, false)
      context.fillStyle = '#ffff00'
      context.fill()
      context.lineWidth = 4
      context.strokeStyle = '#aaa'
      context.stroke()
      context.closePath()
  # Last circle
  context.beginPath()
  context.arc(window.snake[window.snake.length-1][0]*70+35, window.snake[window.snake.length-1][1]*70+35, 28, 0, 2*Math.PI, false)
  context.fillStyle = '#dfdf00'
  context.lineWidth = 4
  context.fill()
  context.strokeStyle = '#aaa'
  context.stroke()
  context.closePath()
  # Letters
  context.beginPath()
  context.font = 'normal normal 600 42px sans-serif'
  context.textAlign = 'center'
  context.textBaseline = 'middle'
  context.fillStyle = '#000000'
  for i in [0..window.snake.length-1]
    letter = letters[window.snake[i][1]*4+window.snake[i][0]]
    if letter == 'Q'
      letter = 'Qu'
    context.fillText(letter, 35+window.snake[i][0]*70, 35+window.snake[i][1]*70)
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
          getLeaderboard()
          getSolution()
      else
        if (window.gameMode != 'limbo')
          alert('Limbo')
          window.gameMode = 'limbo'
          $('input#words').val('Spiel auswerten ...')
          disableGame()
  $('span#timer').html( ((t/60)|0).toString() + ':' + ('0' + (t%60).toString())[-2..])
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
  if window.maintenance
    clearInterval(window.gameInterval) if window.gameInterval
    window.Location.href='/maintenance'
    window.location.reload()
    return
  $.get('/solution')

getLeaderboard = () ->
  $.get('/leaderboard')

startGame = () ->
  if window.maintenance
    clearInterval(window.gameInterval) if window.gameInterval
    window.Location.href='/maintenance'
    window.location.reload()
    return
  $('div#solutiondiv').hide()
  $('div#guessesdiv').show()
  $('canvas#field').load('/new', null, (responseText, textStatus, XMLHttpRequest) ->
    if XMLHttpRequest.getResponseHeader('X-Refreshed') == '0'
      $('div#solution').html('')
      $('div#guesses').html('')
      $('td#cwords').html('0')
      $('td#cpoints').html('0')
    $("canvas#field")
      .attr("data-letters", responseText)
      .css('background-color', '#ffffff')
    showDice(true)
    $('input#words')
      .removeAttr('disabled')
      .val('')
    $('input#words').focus() unless $('input#chat_chat').is(':focus')
    getLeaderboard()
  )

disableGame = () ->
  window.mouseDown = 0
  $('input#words').attr('disabled', 'disabled')
  $('canvas#field').css('background-color', '#eee')
  $('div#solutiondiv').show()
  $('div#guessesdiv').hide()
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
