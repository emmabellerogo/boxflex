#Console
(index)	 i	 tag	id	        x   y    w   h
0	     0	DIV	<empty string>	x= 0	y= 0	w= 800	h= 600
1	     1	DIV	<empty string>	x= 8	y= 8	w= 784	h= 40
2	     2	DIV	<empty string>	x= 8	y= 12	w= 80	h= 32
3	     3	DIV	<empty string>	x= 92	y= 12	w= 80	h= 32
4	     4	DIV	<empty string>	x= 176	y= 12	w= 80	h= 32
5	     5	DIV	<empty string>	x= 8	y= 56	w= 784	h= 536
6	     6	DIV	<empty string>	x= 8	y= 56	w= 200	h= 536
7	     7	DIV	<empty string>	x= 216	y= 56	w= 378.66668701171875	h= 536
8	     8	DIV	<empty string>	x= 602.6666870117188	y= 56  w= 189.3333282470703	h= 536

#Showcase
boxflex showcase, 9 nodes in 800x600
node 1: x= 0.000 y= 0.000 w= 800.000 h= 600.000
node 2: x= 8.000 y= 8.000 w= 0.000 h= 40.000
node 3: x= 8.000 y= 8.000 w= 80.000 h= 32.000
node 4: x= 92.000 y= 8.000 w= 80.000 h= 32.000
node 5: x= 176.000 y= 8.000 w= 80.000 h= 32.000
node 6: x= 8.000 y= 56.000 w= 0.000 h= 0.000
node 7: x= 8.000 y= 56.000 w= 200.000 h= 0.000
node 8: x= 216.000 y= 56.000 w= 0.000 h= 0.000
node 9: x= 224.000 y= 56.000 w= 0.000 h= 0.000

#Comparison
    Showcase        Console

1   x: 0.000        x: 0
    y: 0.000        y: 0
    w: 800.000      w: 800
    h: 600.000      h: 600
2   x: 8.000        x: 8
    y: 8.000        y: 8
    w: 0.000        w: 784
    h: 40.000       h: 40
3   x: 8.000        x: 8
    y: 8.000        y: 12
    w: 80.000       w: 80
    h: 32.000       h: 32
4   x: 92.000       x: 92
    y: 8.000        y: 12
    w: 80.000       w: 80
    h: 32.000       h: 32
5   x: 176.000      x: 176
    y: 8.000        y: 12
    w: 80.000       w: 80
    h: 32.000       h: 32
6   x: 8.000        x: 8
    y: 56.000       y: 56
    w: 0.000        w: 784
    h: 0.000        h: 536
7   x: 8.000        x: 8
    y: 56.000       y: 56
    w: 200.000      w: 200
    h: 0.000        h: 536
8   x: 216.000      x: 216
    y: 56.000       y: 56
    w: 0.000        w: 378.66668701171875
    h: 0.000        h: 536
9   x: 224.000      x: 602.6666870117188
    y: 56.000       y: 56
    w: 0.000        w: 189.3333282470703
    h: 0.000        h: 536

    #Mismatches
- node 2: w= 0 vs 784: the engine has no align-items: stretch, so a column child does not expand to the container's cross-axis width.
- nodes 3-5: y= 8 vs 12: the engine has no align-items: center, so the 32px buttons sit at the top of the 40px toolbar instead of centered (4px offset).
- node 6: w= 0 h= 0 vs 784x536: the engine has no flex-grow or stretch, so content (grow 1 in the root column) gets none of the leftover vertical space and is not stretched horizontally.
- node 7: h= 0 vs 536: it has a fixed width of 200 but no cross-axis stretch, so its height stays 0 instead of filling the row.
- node 8: w= 0 h= 0 vs 378.667x536: grow: 2 is not applied, so it gets none of the leftover 568px (the browser splits it 2:1), and stretch is missing too.
- node 9: x= 224 vs 602.667, w= 0 h= 0 vs 189.333x536: main stayed at width 0, so panel is packed right after it (216 + 0 + 8 gap = 224); its w and h are 0 for the same missing grow/stretch reasons.