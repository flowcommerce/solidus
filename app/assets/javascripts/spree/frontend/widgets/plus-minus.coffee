Widget.register 'plus-minus',
  $init: (node) ->
    @root = $ @node

    @state =
      min: parseInt(@root.attr('min') || 0)
      max: parseInt(@root.attr('max') || 9)

    @value = parseInt(node.value)
    @input = node.outerHTML

    @root.before @image('minus', 'remove')
    @root.after  @image('plus', 'add')

  image: (name, action) ->
    css = 'width: 24px; height: 24px; vertical-align: middle; position: relative; top: -3px; margin: 0 5px; cursor: pointer;'

    """<img src="/images/#{name}.png" style="#{css}" onclick="$w('##{@node.id}').#{action}()" />"""

  add: ->
    @value += 1 if @value < @state.max
    @render()

  remove: ->
    @value -= 1 if @value > @state.min
    @render()

  render: ->
    @root.val @value
