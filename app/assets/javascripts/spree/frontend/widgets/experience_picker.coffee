Widget.register 'experience_picker',
  $init: ->
    @root = $ @node

    @state =
      open: false

    # on flag click, toggle country picker popup
    @root.find('img').first().attr('onclick', @$parse('$$.toggle();'))

    @flag = @root.html()

    # experiences are json encoded in data field
    @experiences = window.app.state.exp.experiences

    # default experience to expose
    @default_country = window.app.state.exp.default

    @root.after @render_popup()

  $render: ->
    popup = $('#choose_experience')

    if @state.open
      # if desktop exp picker is visible
      if $('#sidebar-pannel:visible')[0]
        # render it in sidebar
        $('#sidebar-data-exp').html popup.html()
        $('#sidebar-data').hide()
      else
        popup.show(200)

    else
      popup.hide()
      $('#sidebar-data-exp').html ''
      $('#sidebar-data').show()

    @flag

  flag_src: (key) ->
    "https://flowcdn.io/util/icons/flags/32/#{key.toLowerCase()}.png"

  toggle: ->
    @state.open = if @state.open then false else true

    @$render()

  render_popup: ->
    first_item = null
    countries  = []

    # deconstruct country experience from array and loop
    for [exp_country, exp_key, exp_name] in @experiences
      opts =
        href: "?flow_experience=#{exp_key}"

      # create link with image and exp name, and push to array
      line_item = $tag 'a.country', opts, =>
        image = $tag 'img', src: @flag_src(exp_country)

        [image, exp_name].join(' ')

      if exp_country == @default_country
        first_item = line_item
      else
        countries.push line_item

    title = '<h5>Select shipping country</h5>'

    $tag '#choose_experience',
     { onclick: '$$.toggle();' },
     title + first_item + '<hr />' + countries.join('')
