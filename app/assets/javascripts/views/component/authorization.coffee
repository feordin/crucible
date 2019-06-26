$(document).ready( -> 
  new Crucible.Authorization()
)

class Crucible.Authorization
  constructor: ->
    @element = $('#authorize-modal')
    return unless @element.length
    @registerHandlers()

  registerHandlers: =>
    $('#conformance-data').on('conformanceLoaded', (event) =>
      conformance_tab = $('#conformance-data').children()
      if conformance_tab.data('auth-type') != "none"
        auth_element = $(".authorization-handle")
        auth_element.removeClass("hidden")
        authUrl = conformance_tab.data('authorize-url')
        $('#authorize_form').attr("action", authUrl)
        auth_enabled = !!auth_element.data('oauthClientId')
        if auth_enabled
          auth_expires_at = new Date() + 10000 # start at a future date if no expiration set
          auth_expires_at = moment.unix(parseInt(auth_element.data('oauthExpiresAt'))).toDate() if !!auth_element.data('oauthExpiresAt')
          auth_expired = auth_expires_at < new Date()
          auth_token_exists = !!auth_element.data('oauthRefreshToken')

          if !auth_expired || auth_token_exists
            auth_element.addClass("authorize-success")
            auth_element.attr('title', '').tooltip()
          else
            auth_element.attr('title', 'Authorization expired.').tooltip()
        else
          auth_element.attr('title', 'Please enter authorization information.').tooltip()

    )
    $("#authorize_form").on('submit', (event) =>
      event.preventDefault()
      oauth_type = $('#oauth_type').find('option:selected').val()
      submit_uri = "/servers/#{$('#conformance-data').data('server-id')}/"

      if oauth_type == "authorization_code"
        submit_uri = submit_uri + "oauth_params"
      else if oauth_type == "client_credentials"
        submit_uri = submit_uri + "oauth_authorize_backend"
      else 
        throw ("Invalid Oauth Type")
 
      $.post(submit_uri,
      {
          oauth_type: $('#oauth_type').find('option:selected').val(),
          client_id: $('#client_id').val(),
          client_secret: $('#client_secret').val(),
          authorize_url: $('#conformance-data').children().data('authorize-url'),
          token_url: $('#conformance-data').children().data('token-url'),
          state: $('#state').val(),
          launch_param: $('#launch_param').val(),
          patient_id: $('#patient_id').val(),
          endpoint_params: $('#endpoint_params').val(),
          scopes: $(event.target).find("[name='scope_vars[]']:checked").map(() ->
                    $(this).val()
                  ).get().join(",")
      },
      'JSON'
      ).success((data)->
        if $("#launch_check").prop('checked')
          $('#launch_param').addClass('used')
        scope = $(event.target).find("[name='scope_vars[]']:checked").map(() ->
          $(this).val()
        ).get().join(" ")
        $("#scope").val(scope)

        endpoint_params = $('#endpoint_params').val()
        if oauth_type == "authorization_code"
          endpoint_params = "&" + endpoint_params

        if oauth_type == "authorization_code"
          window.location.assign(event.target.action + "?" + $("input.used").serialize() + endpoint_params)
        else if oauth_type == "client_credentials"
          window.location.reload()

      )
      return false
    )


    $("#delete-authorization").on('click', (event) =>
      event.preventDefault()
      $.post("/servers/#{$('#conformance-data').data('server-id')}/delete_authorization",
      {
        state: $('#state').val()
      },
      'JSON'
      ).success( (data) =>
        window.location.reload()
      )
    )
