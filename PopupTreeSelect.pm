package HTML::PopupTreeSelect;
use 5.006;
use strict;
use warnings;

use Carp qw(croak);
use HTML::Template 2.6;

our $VERSION = "1.0";

=head1 NAME

HTML::PopupTreeSelect - HTML popup tree widget

=head1 SYNOPSIS

  use HTML::PopupTreeSelect;

  # setup your tree as a hash structure.  This one sets up a tree like:
  # 
  # - Root
  #   - Top Category 1
  #      - Sub Category 1
  #      - Sub Category 2
  #   - Top Category 2

  my $data = { label    => "Root",
               value    => 0,              
               children => [
                            { label    => "Top Category 1",
                              value    => 1,
                              children => [
                                           { label => "Sub Category 1",
                                             value => 2
                                           },
                                           { label => "Sub Category 2",
                                             value => 3
                                           },
                                          ],
                            },
                            { label  => "Top Category 2",
                              value  => 4 
                            },
                           ]
              };


  # create your HTML tree select widget.  This one will call a
  # javascript function 'select_category(value)' when the user selects
  # a category.
  my $select = HTML::PopupTreeSelect->new(name         => 'category',
                                          data         => $data,
                                          title        => 'Select a Category',
                                          button_label => 'Choose',
                                          onselect     => 'select_category');

  # include it in your HTML page, for example using HTML::Template:
  $template->param(category_select => $select->output);
 
=head1 DESCRIPTION

This module creates an HTML popup tree selector.  The HTML and
Javascript produced will work in Mozilla 1+ (Netscape 6+) on all
operating systems and Microsoft IE 5+ on Windows and Mac.  For an
example, visit this page:

  http://sam.tregar.com/html-popuptreeselect/example.html

I based the design for this widget on the xTree widget from WebFX.
You can find it here:

  http://webfx.eae.net/dhtml/xtree/

=head1 INSTALLATION

To use this module you'll need to copy the contents of the images/
directory in the module distribution into a place where your webserver
can serve them.  If that's not the same place your CGI will run from
then you need to set the image_path parameter when you call new().
See below for details.

=head1 INTERFACE

=head1 new()

new(), is used to build a new HTML selector.  You call it with a
description of the tree to display and get back an object.  Call it
with following parameters:

=over

=item name

A unique name for the tree selector.  You can have multiple tree
selectors on a page, but they must have unique names.  Must be
alpha-numeric and begin with a letter.

=item data

This must be a hash reference containing the following keys:

=over

=item label (required)

The textual label for this node.

=item value (required)

The value passed to the onselect handler or set in the form_field when
the user selects this node.

=item open (optional)

If set to 1 this node will start open (showing its children).  By
default all nodes start closed.

=item children (optional)

The 'children' key may point to an array of hashes with the same keys.
This is the tree structure which will be displayed in the tree
selector.

=back

See SYNOPSIS above for an example of a valid data structure.

=item title

The title of the window which pops up.

=item button_label (optional)

The widget pops up when the user presses a button. This field gives
the label for the button.  Defaults to "Choose".

=item onselect (optional)

Specifies a Javascript function that will be called when an item in
the tree is selected.  Recieves the value of the item as a single
argument.  The default is for nothing to happen.

=item form_field (optional)

Specifies a form field to recieve the value of the selected item.
This provides a no-javascript means to use this widget (although the
widget itself, of course, uses great gobs of javascript).

=item form_field_form (optional)

Specifies the form in which to find the C<form_field> specified.  If
 not included the first form on the page will be used.

=item include_css (optional)

Set this to 0 and the default CSS will not be included in the widget
output.  This allows you to include your own CSS which will be used by
your widget.  Modifying the CSS will allow you to control the fonts,
colors and spacing in the output widget.

If you run the widget with include_css set to 1 then you can use that
output as a base on which to make changes.

=item image_path (optional)

Set this to the URL to the images for the widget.  These files should
be copied from the images directory in the module distribution into a
place where your webserver can reach them.  By default this is empty
and the widget expects to find images in the current directory.

=back

=head1 output()

Call output() to get HTML from the widget object to include in your
page.

=cut

=head1 CAVEATS

=over 4

=item *

Under IE you'll find that select boxes show through the select window.
This is a well known bug in IE's CSS positioning support and as far as
I know there's nothing I can do about it.  Careful form design is the
only solution.  Please contact me if you know different!

=item *

Performance on huge trees isn't great, but should improve in future
versions.  This version should be usable up to around 10,000 nodes.

=item *

The javascript used to implement the widget needs control over
the global document.onmousedown handler.  This means that 

=back

=head1 TODO

Here are some possible directions for future development.  Send me a
patch for one of these and you're guaranteed a place in F<Changes>.

=over

=item *

Allow each node to specify its own icon.  Right now every node uses
C<closed_node.png> and C<open_node.png>.

=item *

Allow the select window to be dragged around by clicking and dragging
the title.

=back

=head1 BUGS

I know of no bugs in this module.  If you find one, please file a bug
report at:

  http://rt.cpan.org

Alternately you can email me directly at C<sam@tregar.com>.  Please
include the version of the module and a complete test case that
demonstrates the bug.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 Sam Tregar

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=head1 AUTHOR

Sam Tregar <sam@tregar.com>

=cut

sub new {
    my $pkg = shift;
    
    # setup defaults and get parameters
    my $self = bless({ button_label  => 'Choose',
                       height        => 300,
                       width         => 300,
                       indent_width  => 25,
                       include_css   => 1,
                       image_path    => ".",
                       @_,
                     }, $pkg);
    
    # fix up image_path to always end in a /
    $self->{image_path} .= "/" unless $self->{image_path} =~ m!/$!;

    # check required params
    foreach my $req (qw(name data title)) {
        croak("Missing required parameter '$req'") unless exists $self->{$req};
    }

    return $self;
}

sub output {
    my $self = shift;
    our $TEMPLATE_SRC;
    my $template = HTML::Template->new(scalarref          => \$TEMPLATE_SRC,
                                       die_on_bad_params => 0,
                                       global_vars       => 1,
                                      );

    # build node loop
    my @loop;
    $self->_output_node(node   => $self->{data},
                        loop   => \@loop,
                       );

    # setup template parameters
    $template->param(loop => \@loop);
    $template->param(map { ($_, $self->{$_}) } qw(name height width 
                                                  indent_width onselect
                                                  form_field form_field_form
                                                  button_label
                                                  button_image title 
                                                  include_css image_path
                                                 ));
                                                    
                
    # get output for the widget
    my $output = $template->output;

    return $output;
}

# recursively add nodes to the output loop
sub _output_node {
    my ($self, %arg) = @_;
    my $node = $arg{node};

    my $id = next_id();
    push @{$arg{loop}}, { label       => $node->{label},
                          value       => $node->{value},
                          id          => $id,
                          open        => $node->{open} ? 1 : 0,
                        };
    
    if ($node->{children} and @{$node->{children}}) {
        $arg{loop}[-1]{has_children} = 1;
        for my $child (@{$node->{children}}) {
            $self->_output_node(node   => $child,
                                loop   => $arg{loop},
                               );
        }
        push @{$arg{loop}}, { end_block => 1 };
    }
    
}

{ 
    my $id = 1;
    sub next_id { $id++ }
}

our $TEMPLATE_SRC = <<END;
<tmpl_if include_css><style type="text/css"><!--

  /* style for the box around the widget */
  .hpts-outer {
     visibility:       hidden;
     position:         absolute;
     top:              0px;
     left:             0px;
     border:           2px outset #333333;
     background-color: #ffffff;
  }

  /* title bar style.  The width here will define a minimum width for
     the widget. */
  .hpts-title {
     padding:          2px;
     margin-bottom:    4px;     
     font-size:        large;
     color:            #ffffff;
     background-color: #aaaaaa;
     width:            200px;
  }

  /* style of a block of child nodes - indents them under their parent
     and starts them hidden */
  .hpts-block {
     margin-left:      24px;
  }

  /* style for the button bar at the bottom of the widget */
  .hpts-bbar {
     padding:          2px;
     text-align:       right;
     margin-top:       10px;     
     background-color: #aaaaaa;
     width:            200px;
  }

  /* style for the buttons at the bottom of the widget */
  .hpts-button {
     background-color: #ffffff;
     color:            #000000;
  }

  /* style for selected labels */
  .hpts-label-selected {
     background:       #98ccfe;
  }

  /* style for labels after being unselected */
  .hpts-label-unselected {
     background:       #ffffff;
  }

--></style></tmpl_if>

<script language="javascript">
  /* record location of mouse on each click */
  var hpts_mouseX;
  var hpts_mouseY;
  document.onmousedown = hpts_loc;


  function hpts_loc(evt) {
        evt = (evt) ? evt : (event) ? event : null;
        if (evt.pageX) {
           hpts_mouseX = evt.pageX;
           hpts_mouseY = evt.pageY;
        } else {
           hpts_mouseX = evt.clientX + document.documentElement.scrollLeft + document.body.scrollLeft;
           hpts_mouseY = evt.clientY + document.documentElement.scrollTop  + document.body.scrollTop;
        }
        return true;
  }

  var <tmpl_var name>_selected_id = -1;
  var <tmpl_var name>_selected_val;
  var <tmpl_var name>_selected_elem;

  /* expand or collapse a sub-tree */
  function <tmpl_var name>_toggle_expand(id) {
     var obj = document.getElementById("<tmpl_var name>-desc-" + id);
     var plus = document.getElementById("<tmpl_var name>-plus-" + id);
     var node = document.getElementById("<tmpl_var name>-node-" + id);
     if (obj.style.display != 'block') {
        obj.style.display = 'block';
        plus.src = "<tmpl_var image_path>minus.png";
        node.src = "<tmpl_var image_path>open_node.png";
     } else {
        obj.style.display = 'none';
        plus.src = "<tmpl_var image_path>plus.png";
        node.src = "<tmpl_var image_path>closed_node.png";
     }
  }

  /* select or unselect a node */
  function <tmpl_var name>_toggle_select(id, val) {
     if (<tmpl_var name>_selected_id != -1) {
        /* turn off old selected value */
        var old = document.getElementById("<tmpl_var name>-line-" + <tmpl_var name>_selected_id);
        old.className = "hpts-label-unselected";
     }

     if (id == <tmpl_var name>_selected_id) {
        /* clicked twice, turn it off and go back to nothing selected */
        <tmpl_var name>_selected_id = -1;
     } else {
        /* turn on selected item */
        var new_obj = document.getElementById("<tmpl_var name>-line-" + id);
        new_obj.className = "hpts-label-selected";
        <tmpl_var name>_selected_id = id;
        <tmpl_var name>_selected_val = val;
     }
  }

  /* it's showtime! */
  function <tmpl_var name>_show() {
        var obj = document.getElementById("<tmpl_var name>-outer");
        obj.style.left = hpts_mouseX + "px";
        obj.style.top  = hpts_mouseY + "px";
        obj.style.visibility = "visible";
  }

  /* user clicks the ok button */
  function <tmpl_var name>_ok() {
        if (<tmpl_var name>_selected_id == -1) {
           /* ahomosezwha? */
           alert("Please select an item or click Cancel to cancel selection.");
           return;
        }

        /* trigger onselect */
        <tmpl_if onselect><tmpl_var onselect>(<tmpl_var name>_selected_val)</tmpl_if>

        /* fill in a form field if they spec'd one */
        <tmpl_if form_field><tmpl_if form_field_form>document.forms["<tmpl_var form_field_form>"]<tmpl_else>document.forms[0]</tmpl_if>.elements["<tmpl_var form_field>"].value = <tmpl_var name>_selected_val;</tmpl_if>
         
        <tmpl_var name>_close();
  }

  function <tmpl_var name>_cancel() {
        <tmpl_var name>_close();
  }

  function <tmpl_var name>_close () {
        /* hide window */
        var obj = document.getElementById("<tmpl_var name>-outer");
        obj.style.visibility = "hidden";         

        /* clear selection */
        if (<tmpl_var name>_selected_id != -1) {
                <tmpl_var name>_toggle_select(<tmpl_var name>_selected_id);
        }
  }

</script>

<div id="<tmpl_var name>-outer" class="hpts-outer">
  <div class="hpts-title"><tmpl_var title></div>
  <tmpl_loop loop>
    <tmpl_unless end_block>
       <div>
          <tmpl_if has_children>
              <img id="<tmpl_var name>-plus-<tmpl_var id>" width=16 height=16 src="<tmpl_var image_path><tmpl_if open>minus<tmpl_else>plus</tmpl_if>.png" onclick="<tmpl_var name>_toggle_expand(<tmpl_var id>)"><span id="<tmpl_var name>-line-<tmpl_var id>" ondblclick="<tmpl_var name>_toggle_expand(<tmpl_var id>)" onclick="<tmpl_var name>_toggle_select(<tmpl_var id>, '<tmpl_var escape=html value>')">
          <tmpl_else>
              <img width=16 height=16 src="<tmpl_var image_path>L.png"><span id="<tmpl_var name>-line-<tmpl_var id>" onclick="<tmpl_var name>_toggle_select(<tmpl_var id>, '<tmpl_var escape=html value>')">
          </tmpl_if>
                 <img id="<tmpl_var name>-node-<tmpl_var id>" width=16 height=16 src="<tmpl_var image_path>closed_node.png">
                 <a href="javascript:void(0);"><tmpl_var label></a>
             </span>
       </div>
       <tmpl_if has_children>
          <div id="<tmpl_var name>-desc-<tmpl_var id>" class="hpts-block" <tmpl_if open>style="display: block"<tmpl_else>style="display: none"</tmpl_if>>
       </tmpl_if>
    <tmpl_else>
      </div>
    </tmpl_unless>
  </tmpl_loop>
  <div class="hpts-bbar">
    <input class=hpts-button type=button value=" Ok " onclick="<tmpl_var name>_ok()">
    <input class=hpts-button type=button value="Cancel" onclick="<tmpl_var name>_cancel()">
  </div>
</div>

<input type=button value="<tmpl_var button_label>" onmouseup="<tmpl_var name>_show()">
END

1;
