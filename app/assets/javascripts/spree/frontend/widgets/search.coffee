Widget.register 'search',
  $init: ->
    @root = $ @node

    @root.attr 'onclick', "$w(this).toggle()"

    @state =
      taxon_id: @root.data('taxon')
      keywords: @root.data('keywords') || ''
      open:     false

    @state.open = true if @state.keywords

    @render() if @state.open

  toggle: ->
    @state.open = if @state.open then false else true
    @render()

  render: ->
    if @state.open
      @root.addClass 'active'
      @render_form()
    else
      @root.removeClass 'active'
      $('#search-form').remove()

  blur_hide: ->
    setTimeout =>
      @toggle() if @state.open
    , 100

  render_form: ->
    form = """
      <form id="search-form" action="/products">
        <input type="hidden" name="taxon" value="#{@state.taxon_id}" />
        <input type="text" name="keywords" value="#{@state.keywords}" onblur="$w('##{@node.id}').blur_hide()" />
      </form>"""

    @root.before(form)

    input = $('#search-form input[name=keywords]')
    input.focus()
    input.val input.val() if @state.keywords



