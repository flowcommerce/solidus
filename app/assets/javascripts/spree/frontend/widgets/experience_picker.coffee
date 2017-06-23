Widget.register 'experience_picker',
  experience_popup_id: '#choose_experience'

  $init: ->
    @root = $ @node
    @experiences = @root.data('experiences')

    @root.click =>
      $(@experience_popup_id).toggle()

  flag_src: (key) ->
    "https://flowcdn.io/util/icons/flags/32/#{key.toLowerCase()}.png"

  toggle: ->
    $(@experience_popup_id).toggle(200)

  $render: ->
    countries = []
    for [exp_country, exp_key, exp_name] in @experiences
      opts =
        style: "display: block; margin-bottom: 10px;"
        href:  "?flow_experience=#{exp_key}"

      countries.push Widget.tag 'a', opts, =>
        image = Widget.tag 'img',
          style: 'width:32px; height: 32px; vertical-align: middle;'
          src:   @flag_src(exp_country)

        [image, exp_name].join(' ')

    opts =
      style:   '-display: none; position: absolute; z-index: 1; margin: -2px 0 0 -241px; width: 250px;  border: 1px solid #aaa; background-color:#eee; padding: 10px 10px 0 10px; text-align: left;'
      onclick: '$$.toggle();'

    data = Widget.tag @experience_popup_id, opts, countries.join('')

    @root.html() + data
