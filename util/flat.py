"""Flat output plugin

Idea copied from libsmi.
"""

import optparse
import sys
import re
import string

from pyang import plugin
from pyang import statements

def pyang_plugin_init():
    plugin.register_plugin(FlatPlugin())

class FlatPlugin(plugin.PyangPlugin):
    def add_output_format(self, fmts):
        self.multiple_modules = True
        fmts['flat'] = self

    def add_opts(self, optparser):
        optlist = [
            optparse.make_option("--flat-help",
                                 dest="flat_help",
                                 action="store_true",
                                 help="Print help on flat symbols and exit"),
            optparse.make_option("--flat-depth",
                                 type="int",
                                 dest="flat_depth",
                                 help="Number of levels to print"),
            optparse.make_option("--flat-path",
                                 dest="flat_path",
                                 help="Subtree to print"),
            ]
        g = optparser.add_option_group("Flat output specific options")
        g.add_options(optlist)

    def setup_ctx(self, ctx):
        if ctx.opts.flat_help:
            print_help()
            sys.exit(0)

    def setup_fmt(self, ctx):
        ctx.implicit_errors = False

    def emit(self, ctx, modules, fd):
        if ctx.opts.flat_path is not None:
            path = string.split(ctx.opts.flat_path, '/')
            if path[0] == '':
                path = path[1:]
        else:
            path = None
        emit_flat(modules, fd, ctx.opts.flat_depth, path)

def print_help():
    print """
Each node is printed as:

<status> <flags> <name> <opts>   <type>

  <status> is one of:
    +  for current
    x  for deprecated
    o  for obsolete

  <flags> is one of:
    rw  for configuration data
    ro  for non-configuration data
    -x  for rpcs
    -n  for notifications

  <name> is the name of the node
    (<name>) means that the node is a choice node
   :(<name>) means that the node is a case node

   If the node is augmented into the tree from another module, its
   name is printed as <prefix>:<name>.

  <opts> is one of:
    ?  for an optional leaf or presence container
    *  for a leaf-list
    [<keys>] for a list's keys

  <type> is the name of the type for leafs and leaf-lists
"""

def emit_flat(modules, fd, depth, path):
    for module in modules:
        bstr = ""
        b = module.search_one('belongs-to')
        if b is not None:
            bstr = " (belongs-to %s)" % b.arg
        fd.write("%s: %s%s\n" % (module.keyword, module.arg, bstr))
        chs = [ch for ch in module.i_children
               if ch.keyword in statements.data_definition_keywords]
        if path is not None and len(path) > 0:
            chs = [ch for ch in chs
                   if ch.arg == path[0]]
            path = path[1:]

        print_children(chs, module, fd, ' ', path, depth)

        rpcs = module.search('rpc')
        if path is not None and len(path) > 0:
            rpcs = [rpc for rpc in rpcs
                    if rpc.arg == path[0]]
            path = path[1:]
        if len(rpcs) > 0:
            fd.write("rpcs:\n")
            print_children(rpcs, module, fd, '', path, depth)

        notifs = module.search('notification')
        if path is not None and len(path) > 0:
            notifs = [n for n in notifs
                      if n.arg == path[0]]
            path = path[1:]
        if len(notifs) > 0:
            fd.write("notifications:\n")
            print_children(notifs, module, fd, '/', path, depth)

def print_children(i_children, module, fd, prefix, path, depth, width=0):
    if depth == 0:
        return
    def get_width(w, chs):
        for ch in chs:
            if ch.keyword in ['choice', 'case']:
                w = get_width(w, ch.i_children)
            else:
                if ch.i_module.i_modulename == module.i_modulename:
                    nlen = len(ch.arg)
                else:
                    nlen = len(ch.i_module.i_prefix) + 1 + len(ch.arg)
                if nlen > w:
                    w = nlen
        return w

    if width == 0:
        width = get_width(0, i_children)

    for ch in i_children:
        newprefix = prefix + '/'+ch.arg
        if ((ch.arg == 'input' or ch.arg == 'output') and
            ch.parent.keyword == 'rpc' and
            len(ch.i_children) == 0 and
            ch.parent.search_one(ch.arg) is None):
            pass
        else:
            print_node(ch, module, fd, newprefix, path, depth, width)

def print_node(s, module, fd, prefix, path, depth, width):
    fd.write("%s%s--" % (prefix, get_status_str(s)))

    if s.i_module.i_modulename == module.i_modulename:
        name = s.arg
    else:
        name = s.i_module.i_prefix + ':' + s.arg
    flags = get_flags_str(s)
    if s.keyword == 'list':
        fd.write(flags + " " + name)
    elif s.keyword == 'container':
        p = s.search_one('presence')
        if p is not None:
            name += '?'
        fd.write(flags + " " + name)
    elif s.keyword  == 'choice':
        m = s.search_one('mandatory')
        if m is None or m.arg == 'false':
            fd.write(flags + ' (' + s.arg + ')?')
        else:
            fd.write(flags + ' (' + s.arg + ')')
    elif s.keyword == 'case':
        fd.write(':(' + s.arg + ')')
    else:
        if s.keyword == 'leaf-list':
            name += '*'
        elif s.keyword == 'leaf' and not hasattr(s, 'i_is_key'):
            m = s.search_one('mandatory')
            if m is None or m.arg == 'false':
                name += '?'
        fd.write("%s %-*s   %s" % (flags, width+1, name, get_typename(s)))

    if s.keyword == 'list' and s.search_one('key') is not None:
        fd.write(" [%s]" % re.sub('\s+', ' ', s.search_one('key').arg))
    fd.write('\n')
    if hasattr(s, 'i_children'):
        if depth is not None:
            depth = depth - 1
        chs = s.i_children
        if path is not None and len(path) > 0:
            chs = [ch for ch in chs
                   if ch.arg == path[0]]
            path = path[1:]
        if s.keyword in ['choice', 'case']:
            print_children(chs, module, fd, prefix, path, depth, width)
        else:
            print_children(chs, module, fd, prefix, path, depth)

def get_status_str(s):
    status = s.search_one('status')
    if status is None or status.arg == 'current':
        return '+'
    elif status.arg == 'deprecated':
        return 'x'
    elif status.arg == 'obsolete':
        return 'o'

def get_flags_str(s):
    if s.keyword == 'rpc' or s.keyword == ('tailf-common', 'action'):
        return '-x'
    elif s.keyword == 'notification':
        return '-n'
    elif hasattr(s, 'i_tree_flags_str'):
        return s.i_tree_flags_str
    elif s.i_config == True:
        return 'rw'
    else:
        return 'ro'

def get_typename(s):
    t = s.search_one('type')
    if t is not None:
        return t.arg
    else:
        return ''
