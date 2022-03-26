clear all
close all
clc

x = -70:0.01:70;

%d = [1.25, 2.5, 3, 4, 5, 7.5, 9, 10, 12.5, 15, 20, 22.5, 25, 27.5, 30];
%d = [30];
d=[10, 1.345*69];
legendLabels = {};
y = NaN(length(x), length(d));
figure(1)
for didx = 1:length(d)
   %disp(['Delta = ', num2str(d(didx))])
   xabs = abs(x);
   y(:, didx) = huber_loss(xabs, d(didx)); 
   plot(x, y(:,didx))
   disp(['Delta = ', num2str(d(didx)), ', huber(0) = ', num2str(huber_loss(0, d(didx)))])
   hold on 
   legendLabels(didx) = cellstr(['d = ', num2str(d(didx))]);
end
xlabel('Difference between Predicted and Target values');
ylabel('Loss');
title('Huber Loss Function');
%legendLabels = split(num2str(d));
%legendLabels = ["d = ", legendLabels];
legend(legendLabels)





function val = huber_loss(a, delta)    
    for i = 1:length(a)
        if abs(a(i)) <= delta
            val(i) = 0.5*(a(i)^2);
        else
            val(i) = delta*(abs(a(i))-delta/2);
        end
    end

    %if abs(a) <= delta
    %    val = 0.5*(a.^2);
    %    fprintf('.');
    %else
    %    val = delta*(abs(a)-delta/2);
    %end
end


