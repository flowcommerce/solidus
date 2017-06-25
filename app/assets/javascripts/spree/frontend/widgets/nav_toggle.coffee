Widget.register 'nav_toggle',
  $init: ->
    @root = $ @node
    @root.click -> $('#sidebar').toggle()
