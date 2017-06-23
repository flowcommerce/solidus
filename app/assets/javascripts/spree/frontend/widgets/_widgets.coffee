'use strict'

# public interface
# $init()       - called on every wiget $init
# $page_init()  - called once on every page
# $render()        - renders renturned html data and inserts to dom node
# $render_data()   - renders only html data, without binding to dom node
# $attr(name, val) - get or set node attribute value

# pro tips
# you will want to write render() functions which will return plain html with $$.func references
# if you want to manualy render data, use render_data() to get html and some other function
# instead of render to bind it to html

@Widget =
  count: 0,
  widgets: {},
  registered_widgets: {},

  register:  (name, obj) ->
    obj.$init ||= -> true

    # method that gets view, are replaces $$ with widget reference
    obj.$get_render_data = (data) ->
      data ||= @render_data()
      data    = if typeof data == 'object' then data.join('') else String(data)
      node_id =  @node.getAttribute('id')
      data.replace(/\$\$\./g, "$w('##{node_id}').")

    obj.render_data = obj.$render

    # default render, just gets view() html and binds to root
    obj.$render = ->
      return unless @render_data
      data = @$get_render_data()
      # @node.innerHTML = data;
      this.$html(data)

    # get or set object attributes
    obj.$attr = (name, data) ->
      return @node.getAttribute(name) if data == undefined
      @node.setAttribute(name, data)
      data

    # destroy widget in memory and dom
    obj.$destroy = (name, value) ->
      delete Widget.widgets[@get('id')]
      @node.parentNode.removeChild @node

    # insert html and load widgets if data
    obj.$html = (data) ->
      if !data
        return @node.innerHTML
      @node.innerHTML = data
      Widget.load_all @node

    # Object.seal(obj)

    obj.$page_init() if obj.$page_init && !@registered_widgets[name]

    @registered_widgets[name] = obj

  load_all: (root) ->
    root = window.document if root == undefined
    widgets = root.getElementsByClassName('w')

    for node in widgets
      continue unless node.nodeName

      id = node.getAttribute(id)
      continue if id && this.widgets[id]

      Widget.bind_to_dom_node(node)

  bind_to_dom_node: (dom_node) ->
    klass   = dom_node.getAttribute('class')
    node_id = dom_node.getAttribute('id')

    unless node_id
      ++@count
      node_id = "widget-#{@count}"
      dom_node.setAttribute('id', node_id)

    widget_name = klass.split(' ')[1]
    widget_opts = @registered_widgets[widget_name]

    # return if widget is not defined
    return alert "Widget #{widget_name} is not registred" unless widget_opts

    # define widget instance
    widget = {}

    # apply basic methods
    widget[key] = widget_opts[key] for key in Object.keys(widget_opts)

    # bind root to root
    widget.node = dom_node

    # $init and render
    widget.$init(dom_node)
    widget.$render()

    # store for easy access
    Widget.widgets[node_id] = widget

  is_widget: (node) ->
    klass = node.getAttribute('class')

    if klass?.split(' ')[0] == 'w'
      node
    else
      undefined

  prop_index: -1
  prop_data: []
  prop: (kind, init_value) ->
    prop_index = @prop_index += 1
    prop_data  = @prop_data

    if typeof kind == 'function'
      return (input) ->
        return prop_data[prop_index] unless input?
        prop_data[prop_index] = kind(input)

    func = (input) ->
      return prop_data[prop_index] unless input?

      prop_data[prop_index] = switch kind.charAt(0)
        when 'i'
          parseInt(input)
        when 's'
          String(input)
        when 'f'
          parseFloat(input)
        when 'b'
          if input then true else false
        when 'd'
          new Date(input)
        else
          alert "Unknown kind '#{kind}'. Supported i(nteger), f(float), s(string), b(oolean), d(ate) and (function)"

    func(init_value) if init_value?

    func

  # Widget.tag 'button.btn.btn-xs', button_name, class: 'btn-primary'
  tag: (name, args...) ->
    # evaluate function if data is function
    args = args.map (el) -> if typeof el == 'function' then el() else el

    # swap args if first option is object
    [opts, data] = if typeof args[0] == 'object' then args else args.reverse()
    opts ||= {}

    # haml style id define
    name = name.replace /#([\w\-]+)/, ->
      opts['id'] = RegExp.$1
      ''
    # haml style class add with a dot
    name_parts = name.split('.')
    name       = name_parts.shift() || 'div'

    if name_parts[0]
      old_class = if opts['class'] then ' '+opts['class'] else ''
      opts['class'] = name_parts.join(' ') + old_class

    node = ['<'+name]

    for key in Object.keys(opts)
      node.push ' '+key+'="'+opts[key]+'"'

    if ['input', 'img'].indexOf(name) > -1
      node.push ' />'
    else
      node.push '>'+data+'</'+name+'>'

    node.join('')

# global widget access function
window.$w = (node) ->
  # get pointer to widget definition
  # $w('tag')
  return Widget.registered_widgets[node] if typeof node == 'string' and node[0] != '#'

  # pointer to widget
  # $w('#tag-picker-1')
  if typeof node == 'string' and node[0] == '#'
    root = document.getElementById(node.split('#', 2)[1])
  else
    root = do ->
      while node
        return node if Widget.is_widget(node)
        node = node.parentNode

  unless root
    console.log 'Widget node not found', node
    return alert('Widget node not found')

  id = root.getAttribute('id')

  unless id
    console.log 'Widget node ID not found', node
    return alert('Widget node ID not found')

  widget = Widget.widgets[id]

  return alert('Widget with ID ' + id + ' not found.') unless widget

  widget

if window.$
  $ -> Widget.load_all()

