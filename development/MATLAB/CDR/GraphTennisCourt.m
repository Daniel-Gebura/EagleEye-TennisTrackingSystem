syms x;
doublesTopline = piecewise(-11.865 < x & 11.885, 5.485, 5.485);
singlesTopline = piecewise(-11.865 < x & 11.885, 4.115, 4.115);
centerLine = piecewise(-6.4 < x & x < 6.4, 0, 0);
singlesBottomline = piecewise(-11.865 < x & 11.885, -4.115, -4.115);
doublesBottomline = piecewise(-11.865 < x & 11.885, -5.485, -5.485);

toplineDoublesCourt = ones(1, 238);
toplineSinglesCourt = ones(1, 238);
centerLineCourt = ones(1, 129);
bottomlineDoublesCourt = ones(1, 238);
bottomlineSinglesCourt = ones(1, 238);

i = 1;
for j = -11.865: 0.1 : 11.865
    toplineDoublesCourt(i)    = subs(doublesTopline, x, j);
    bottomlineDoublesCourt(i) = subs(doublesBottomline, x, j);
    toplineSinglesCourt(i)  = subs(singlesTopline, x, j);
    bottomlineSinglesCourt(i) = subs(singlesBottomline, x, j);
    i = i + 1;
end 

i = 1;
for j = -6.4 : 0.1 : 6.4
    centerLineCourt(i) = subs(centerLine, x, j);
    i = i + 1;
end

syms y
leftLine = piecewise(-5.485 < y & y < 5.485, -11.865, -11.865); 
leftServiceLine = piecewise(-4.115 < y & y < 4.115, -6.4, -6.4);
netLine = piecewise(-5.485 < y & y < 5.485, 0, 0);
rightServiceLine = piecewise(-4.115 < y & y < 4.115, 6.4, 6.4);
rightLine = piecewise(-5.485 < y & y < 5.485, 11.865, 11.865); 

leftLineCourt = ones(1, 110);
leftServiceLineCourt = ones(1, 83);
netlineCourt = ones(1, 110);
rightServiceLineCourt = ones(1, 83);
rightLineCourt = ones(1, 110);

i = 1;
for j = -5.485 : 0.1 : 5.485
   leftLineCourt(i) = subs(leftLine, y, j); 
   netlineCourt(i) = subs(netLine, y, j);
   rightLineCourt(i) = subs(rightLine, y, j);
   i = i + 1;
end

i = 1;
for j = -4.115 : 0.1 : 4.115
    leftServiceLineCourt(i) = subs(leftServiceLine, y, j);
    rightServiceLineCourt(i) = subs(rightServiceLine, y, j);
    i = i + 1;
end

figure
hold on
plot([ -11.865: 0.1 : 11.865], toplineDoublesCourt,'black');
plot([ -11.865: 0.1 : 11.865], toplineSinglesCourt, 'black');
plot([-6.4 : 0.1 : 6.4], centerLineCourt, 'black');
plot([ -11.865: 0.1 : 11.865], bottomlineSinglesCourt, 'black');
plot([ -11.865: 0.1 : 11.865], bottomlineDoublesCourt, 'black');
plot(leftLineCourt, [-5.485 : 0.1 : 5.485], 'black');
plot(netlineCourt, [-5.485 : 0.1 : 5.485], 'black');
plot(leftServiceLineCourt, [-4.115 : 0.1 : 4.115], 'black');
plot(rightServiceLineCourt, [-4.115 : 0.1 : 4.115], 'black');
plot(rightLineCourt, [-5.485 : 0.1 : 5.485], 'black');
hold off
