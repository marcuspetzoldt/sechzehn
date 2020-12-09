$(document).on('click', 'button[data-action]', () ->
  url = $(this).attr('data-link')
  action = $(this).attr('data-action')
  name = $('input#user_name').val()
  $.ajax(
    url: url,
    type: 'POST',
    beforeSend: (xhr) -> xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')),
    data: {
      form: action,
      name: name
    }
  ).done( (result) ->
    $('div#users_form_signin').html(result)
  )
);
