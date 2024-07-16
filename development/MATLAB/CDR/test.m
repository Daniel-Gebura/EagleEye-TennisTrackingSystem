calculatedDepths = calculatedDepths(3:82);
calculatedDepths_t = calculatedDepths_t(3:82);
% Plotting both depths arrays against t
figure; % Create a new figure window
windowSize = 3;
movingAveragedCalculatedDepths = smooth(calculatedDepths,windowSize);
movingAveragedT = smooth(calculatedDepths_t, windowSize);
[Coefficients, Structure] = polyfit(movingAveragedT,movingAveragedCalculatedDepths,2);
polynomialFunction = @(inputTime) Coefficients(1) * inputTime ^ 2 + Coefficients(2) * inputTime + Coefficients(3);

N = size(movingAveragedT);

polyFit = zeros(1, N(1));

for i = 1 : N(1)
    polyFit(i) = polynomialFunction(movingAveragedT(i));
end

hold on
plot(movingAveragedT, polyFit, '-x', 'DisplayName', 'Moving Averaged PolyFit')
%plot(movingAveragedT, movingAveragedCalculatedDepths, '-o', 'DisplayName', 'Moving Averaged Calculated Depth' )
plot(calculatedDepths_t, calculatedDepths, '-o', 'DisplayName', 'Calculated Depths');
plot(calculatedDepths_t, actualDepths, '-s', 'DisplayName', 'Actual Depths from File');
hold off;

% Formatting the graph
xlabel('Frame Number (t)');
ylabel('Depth');
title('Comparison of Calculated Depths and Actual Depths');
legend show; % Show legend to identify the plots