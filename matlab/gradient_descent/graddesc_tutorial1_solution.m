%% Generate a two dimensional stimulus (e.g two pixels) with correlations and 100 samples (e.g. points in time)
% First pixel data
nsamp = 100;
x1 = randn(1,nsamp);
% Second pixel that is correlated with the first
x2 = .4*x1 + .6*randn(1,nsamp);
% Concatinate into a stimulus matrix
x = [x1; x2];

%% Generate a filter and the corresponding one dimensional response 
% Set weights on each channel
h = [5; 7];
% Make response of system
y = x'*h;


%% set up a range of potential values for each weight (you are solving 
% the equation and are looking for possible correct answers)
[h1,h2] = meshgrid(-1:.2:10, -1:.2:10);
hs = [h1(:)'; h2(:)'];
% get responses from each set of weights
ys = x'*hs;
% calculate error between the response, y, and each of the possible responses, ys.  
err = sum((repmat(y,1,size(ys,2)) - ys).^2,1);
% reshape for plotting
err = reshape(err,size(h1));

%% plot contour of error surface. Note the shape of the surface is angled
% because the two variable are correlated.
figure(1);
contour(h1,h2,err,50);

%% Problem 1.
% Plot the actual solution as a large cross on the contour plot
% What is the value of the error surface at this solution?

hold on; plot(h(1), h(2), 'kx', 'MarkerSize', 14); hold off;


%% Problem 2. 
% Generate a new response yr (for y real) that includes noise (SNR ~1). 
% Repeat some of the code above to obtain
% a new error surface as you would with real data.  Plot
% this on figure 2 and compare to figure 1. Calculate the minimum of this
% error and compare to the minimum of the noise free error surface.
% What happens to the error surface if you only have 10 data points (and noise)? 
% Calculate that one and plot in on a third plot.

% The new response:
SNR = 1;
yr = y + (std(y)/sqrt(SNR))*randn(1,nsamp)';

% calculate error between the response and each of the possible responses  
err_real = sum((repmat(yr,1,size(ys,2)) - ys).^2,1);

% reshape for plotting
err_real = reshape(err_real,size(h1));

% plot the contour of error surface.
figure(2);
contour(h1,h2,err_real,50);

% With fewer data points 
nsampsmall = 10;
xsmall = x(:, 1:nsampsmall);
yrsmall = yr(1:nsampsmall, 1);
% calculate error between the response and each of the possible responses  
err_real_small = sum((repmat(yrsmall,1,size(ys,2)) - ys(1:nsampsmall, :)).^2,1);

% reshape for plotting
err_real_small = reshape(err_real_small,size(h1));
figure(3);
contour(h1,h2, err_real_small, 50);

% We notice that the error surfaces do not become noisy but that the minimum moves either
% when we add noise or when we reduce the number of points.
% The minimum value in the noisys situation is also a postive - non-zero number.

%% Problem 3.
% Solve for the Least MSE solution using the analytical solution (calculate the cross and auto correlation and take ratio).
% You migh also check out what the \ does in matlab with the raw x and y
% vectors.
% Plot this solution as well as the correct solutions on your contour plots of figures 2 and 3.  

cross_xy = (x*yr)./nsamp;
auto_xx = x*x'./nsamp;
hpred = auto_xx\cross_xy;   

% Note that this works as well
hpred_matlab = x'\yr;
% You can check that hpred = hpred_matlab.  THis works because the
% mldivide() (same as \) command in matlab solves the system of equation by LMSE.
% I recommend more explicitly writing down the computations.

% plot solution on contour
figure(2);
hold on; 
plot(hpred(1), hpred(2), 'rx','MarkerSize', 14);   % The MSE solution in red
plot(h(1), h(2), 'kx', 'MarkerSize', 14);  % The actual solution in black
hold off;

% Repeat for the subset
cross_xy_small = (xsmall*yrsmall)./nsampsmall;
auto_xx_small = xsmall*xsmall'./nsampsmall;
hpred_small = auto_xx_small\cross_xy_small;   % Shoulnd't this be xy

% plot solution on contour
figure(3);
hold on; 
plot(hpred_small(1), hpred_small(2), 'rx','MarkerSize', 14);   % The MSE solution in red
plot(h(1), h(2), 'kx', 'MarkerSize', 14);  % The actual solution in black
hold off;

%% Problem 4. Now we're going to solve using gradient descent to show that you get the same answer as the MSE
%  You are going to solve it using the x and yr data. Use the
%  analytical solution for the gradient.  Fill in the missing code and
%  print out the final solution. Stop the descent when error is less than
%  the noise power.

% set a step size and a fixed number of maximum steps
nsteps = 1000;
vary = var(yr);
hscale = 10;    % This is a guess on the variance of the h parameters
stepsize = (hscale./vary); % This is to get stepsizes with the correct units.

% initialize hhat at origin and allocate space
hhat = zeros(2, nsteps+1);   %  We will be keeeping track of hhat during our descent

% loop for a certain number of iterations
% and mark when your reach the noise level...
totstep = -1;
for ii=1:nsteps
    
    % calculate the gradient at hhat
    grad = (x*(x'*hhat(:,ii) - yr))./nsamp;
    
    % update hhat using stepsize and gradient
    hhat(:,ii+1) = hhat(:,ii) - stepsize*grad;
    
    % calculate error
    err = mean(((x'*hhat(:,ii+1)-yr)).^2);
    
    % set stopping condition when error is below noise power.
    if err < vary/(SNR+1)
       if (totstep == -1)
           totstep = ii+1;
       end
    end
    
end
if (totstep == -1 ) 
    totstep = ii+1;
end
fprintf(1, 'Gradient solution of h = [%.2f, %.2f] reached after %d steps\n', hhat(1,totstep), hhat(2,totstep), totstep);


%% Problem 5.  Plot descent path on contour of figure 2.
% Comment on why early stopping could give you a more general solution.  

figure(2);
hold on; 
plot(hhat(1,1:totstep), hhat(2,1:totstep), 'Linewidth', 2);
plot(hhat(1,totstep:end), hhat(2, totstep:end));
hold off;

%% Problem 6. 
% Repeat the calculations of Problem 4 and 5 with figure 3. 


hhatsmall = zeros(2, nsteps);   %  We will be keeeping track of hhat during our descent

% loop for a certain number of iterations
totstepsmall = -1;
for ii=1:nsteps
    
    % calculate the gradient at hhat
    grad = (xsmall*(xsmall'*hhatsmall(:,ii) - yrsmall))./nsampsmall;
    
    % update hhat using stepsize and gradient
    hhatsmall(:,ii+1) = hhatsmall(:,ii) - stepsize*grad;
    
    % calculate error
    err = mean(((xsmall'*hhatsmall(:,ii)-yrsmall)).^2);
    
    % set stopping condition
    if err < var(yrsmall)/(SNR+1)
        if totstepsmall == -1
            totstepsmall = ii;
        end
    end
    
end

if (totstepsmall == -1 ) 
    totstepsmall = ii;
end
fprintf(1, 'Gradient solution of hsmall = [%.2f, %.2f] reached after %d steps\n', hhatsmall(1,totstepsmall), hhatsmall(2,totstepsmall), totstepsmall);

figure(3);
hold on; 
plot(hhatsmall(1,1:totstepsmall), hhatsmall(2,1:totstepsmall), 'Linewidth', 2);
plot(hhatsmall(1, totstepsmall:end), hhatsmall(2, totstepsmall:end));
hold off;

%% Problem 6. Solve using coordinate descent
% Fill the code to solve the problem using coordinate descend and plot the 
% trajectories on figure 2 and figure 3 the path with a different
% color line.

nsteps = 1000;
% initialize hhatcd to origin and make space so that we can keep track
% during the descent
hhatcd = zeros(2, nsteps+1);   %  We will be keeeping track of hhat during our descent

% loop for a certain number of iterations
totstepcd = -1;
for ii=1:nsteps
    
    % calculate the gradient
    grad = (x*(x'*hhatcd(:,ii)-yr))./nsamp;
    
    % find the maximum of the gradient
    [d,idx] = max(abs(grad));
    
    % update hhat so that only the dimension with largest gradient changes
    hhatcd(:,ii+1) = hhatcd(:,ii);
    hhatcd(idx,ii+1) = hhatcd(idx,ii) - stepsize*grad(idx);
    
    % calculate error
    err = mean(((x'*hhatcd(:,ii+1) - yr)).^2);
    
    % set stopping criteria
    if err < vary/(SNR+1)
        if (totstepcd == -1)
            totstepcd = ii+1;
        end
    end
    
    % end loop
end
if (totstepcd == -1)
    totstepcd = ii;
end
fprintf(1, 'Coordinate descent solution of h = [%.2f, %.2f] reached after %d steps\n', hhatcd(1,totstepcd), hhatcd(2,totstepcd), totstepcd);

% plot coordinate descent path on contour
figure(2);
hold on; 
plot(hhatcd(1,1:totstepcd), hhatcd(2,1:totstepcd), 'r', 'Linewidth', 2);
plot(hhatcd(1, totstepcd:end), hhatcd(2,totstepcd:end), 'r');
hold off;

% Repeat for the smaller data shown in figure 3. 
% initialize hhatcdsmall to origin and make space so that we can keep track
% during the descent
hhatcdsmall = zeros(2, nsteps+1);   %  We will be keeeping track of hhat during our descent

% loop for a certain number of iterations
totstepcdsmall = -1;
for ii=1:nsteps
    
    % calculate the gradient
    grad = (xsmall*(xsmall'*hhatcdsmall(:,ii)-yrsmall))./nsampsmall;
    
    % find the maximum of the gradient
    [d,idx] = max(abs(grad));
    
    % update hhat so that only the dimension with largest gradient changes
    hhatcdsmall(:,ii+1) = hhatcdsmall(:,ii);
    hhatcdsmall(idx,ii+1) = hhatcdsmall(idx,ii) - stepsize*grad(idx);
    
    % calculate error
    err = mean(((xsmall'*hhatcdsmall(:,ii+1) - yrsmall)).^2);
    
    % set stopping criteria
    if err < var(yrsmall)/(SNR+1)
        if (totstepcdsmall == -1)
            totstepcdsmall = ii+1;
        end
    end
end

if (totstepcdsmall == -1)
    totstepcdsmall = ii+1;
end
fprintf(1, 'Coordinate descent solution of hsmall = [%.2f, %.2f] reached after %d steps\n', hhatcdsmall(1,totstepcdsmall), hhatcd(2,totstepcdsmall), totstepcdsmall);

% plot coordinate descent path on contour
figure(3);
hold on; 
plot(hhatcdsmall(1,1:totstepcdsmall), hhatcdsmall(2,1:totstepcdsmall), 'r', 'Linewidth', 2);
plot(hhatcdsmall(1,totstepcdsmall:end), hhatcdsmall(2,totstepcdsmall:end), 'r');
hold off;

%% Problem 7.  Show on figures 2 and 3, the path corresponds to ridge regression.
% Remember that you calculated the auto and cross correlation in problem 3.

% The auto and cross correlation were obtained in Problem 3 with
% cross_xy = (x*yr)./nsamp;
% auto_xx = x*x'./nsamp;

% Eigenvalue decomposition of auto_xx using the svd
[u,s,v] = svd(auto_xx);

% hyper parameter lambda as fraction of largest eigenvalue

l=[10 1 0.5 0.1 0.05 0.01 .005 .001 .0005 .0001 .00001 0];
nlambda = length(l);
maxs = max(diag(s));
hr = zeros(2, nlambda);
totstepridge = -1;

% Loop over different ridge parameters
for ii=1:nlambda
    
    % Calcuate inverse for each ridge parameter
    XXinv = v'*diag(1./(diag(s)+(maxs*l(ii))))*u;
    
    % Estimate parameters for each ridge value
    hr(:,ii) = XXinv*cross_xy;
    
        % calculate error
    err = mean(((x'*hr(:,ii) - yr)).^2);
    
    % set stopping criteria
    if err < var(yr)/(SNR+1)
        if (totstepridge == -1)
            totstepridge = ii;
        end
    end
end
if (totstepridge == -1)
    totstepridge = ii;
end
% plot ridge path on contour
figure(2);
hold on;
plot(hr(1,1:totstepridge), hr(2,1:totstepridge), 'g', 'Linewidth', 2);
plot(hr(1,totstepridge:end), hr(2,totstepridge:end), 'g');
hold off;

% Repeat for figure 3
% The auto and cross correlation were obtained in Problem 3 with
% cross_xy_small = (xsmall*yrsmall)./nsampsmall;
% auto_xx_small = xsmall*xsmall'./nsampsmall;

% Eigenvalue decomposition of auto_xx using the svd
[u,s,v] = svd(auto_xx_small);

% We are getting a new largest eigenvalue
maxs = max(diag(s));
hrsmall = zeros(2, nlambda);

% Loop over different ridge parameters
totstepridgesmall = -1;
for ii=1:nlambda
    
    % Calcuate inverse for each ridge parameter
    XXinv = v'*diag(diag(s)./(diag(s).^2+(maxs*l(ii)).^2))*u;
    
    % Estimate parameters for each ridge value
    hrsmall(:,ii) = XXinv*cross_xy_small;
    
    err = mean(((xsmall'*hrsmall(:,ii) - yrsmall)).^2);
    
    % set stopping criteria
    if err < var(yrsmall)/(SNR+1)
        if (totstepridgesmall == -1)
            totstepridgesmall = ii;
        end
    end
end
if (totstepridgesmall == -1)
    totstepridgesmall = ii;
end

% plot ridge path on contour
figure(3);
hold on;
plot(hrsmall(1,1:totstepridgesmall), hrsmall(2,1:totstepridgesmall), 'g', 'Linewidth', 2);
plot(hrsmall(1,totstepridgesmall:end), hrsmall(2,totstepridgesmall:end), 'g');
hold off;

