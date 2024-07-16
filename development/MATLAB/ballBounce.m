function [x, y, z] = ballBounce(t)
    coeff = 0.75;
    if t <= 1.41
        x = 1;
        y = (-4.9) * t ^ 2 + 5;
        z = 2;
    else
        x = 1;
        y = (-4.9) * t ^ 2 + coeff * (9.8) * t;
        z = 2;
   end
end