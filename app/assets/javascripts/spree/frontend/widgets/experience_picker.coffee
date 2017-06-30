Widget.register 'experience_picker',
  experience_popup_id: '#choose_experience'

  $init: ->
    @root = $ @node

    # on flag click, toggle country picker popup
    @root.find('img').first().attr('onclick', '$$.toggle();')

    @flag = @root.html()

    # experiences are json encoded in data field
    @experiences = window.app.state.exp.experiences

    # default experience to expose
    @default_country = window.app.state.exp.default

  flag_src: (key) ->
    "https://flowcdn.io/util/icons/flags/32/#{key.toLowerCase()}.png"

  toggle: ->
    popup = $(@experience_popup_id)
    alert popup
    if popup[0]
      popup.remove()
    else
      popup.toggle(200)

  render_popup: ->
    first_item = null
    countries  = []

    # deconstruct country experience from array and loop
    for [exp_country, exp_key, exp_name] in @experiences
      opts =
        href:  "?flow_experience=#{exp_key}"

      # create link with image and exp name, and push to array
      line_item = Widget.tag 'a.country', opts, =>
        image = Widget.tag 'img', src: @flag_src(exp_country)

        [image, exp_name].join(' ')

      if exp_country == @default_country
        first_item = line_item
      else
        countries.push line_item

    title = '<h5>Select shipping country</h5>'

    $parse ->
      title + first_item + '<hr />' + countries.join('')

    @flag +
    Widget.tag @experience_popup_id,
     { onclick: '$$.toggle();' },
     @render_popup()

  $render: ->
    # render popup data with countries

