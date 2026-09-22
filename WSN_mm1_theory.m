% Week 3 Black Box Simulation of WSN 
% with M/M/1 Queueing model - Theoretical model

%The inputs are: numSensors, commRadius, lambda_per_s, rho_target
% Ouputs are: results

function [results] = WSN_mm1_theory(numSensors, commRadius, lambda_per_s, rho_target)
% Inputs:
%   numSensors   : number of sensors
%   commRadius   : communication radius
%   lambda_per_s : per-sensor arrival rate 
%   rho_target   : target utilization for loaded nodes 
%
% Outputs:
%   avgDelay_theory : overall avg delay in system
%   results         : struct with per-node theory results

    

    % Checking whether the provided utilization value is valid. If not,
    % warns user for instability
    if rho_target <= 0 || rho_target >= 1
        warning('rho_target=%.3f is outside (0,1). Unstable', rho_target);
    end

    % --- 1) Build sensors + nodes ---
    sensors = generate_sensors(numSensors, commRadius);
    nodes = generate_nodes();
    M = numel(nodes); % numel is used to get the number of elements in a list or array

    % --- 2) Assign sensors to nearest in-range node ---
    nearestNode = assign_sensors_to_nodes(sensors, nodes);
    plot_network(sensors, nodes, nearestNode);

    % --- 3) True arrival rates per node --- 
    % Each node gets a different rate based on sensors that get attached to it
    n_per_node = zeros(M,1); % initialize array of zeros 
    for m = 1:M
        n_per_node(m) = sum(nearestNode == m); %gets the sum of of sensors near each node
    end
    lambda_node_true = n_per_node .* lambda_per_s; % the actual rate at each node based on the number of sensors per node

    %disp('Node Arrival Rates:')
    %disp(lambda_node_true);

    % --- 4) Derive μ per node from target ρ ---
    mu_vec = zeros(M,1);
    has_load = (lambda_node_true > 0); % checks to see if the vector has any arrivals
    mu_vec(has_load) = lambda_node_true(has_load) ./ rho_target;  % if there is an arrival computes the service rate at each node μ_m = λ_m / ρ_target
    mu_vec(~has_load) = 1;  % if some nodes are idle (no arrivals), assign an arbitrary rate

    %disp('Node Processing Rates:')
    %disp(mu_vec);

    % --- 5) Theoretical M/M/1 metrics per node ---
    % For M/M/1 (λ < μ):
    %   rho = λ/μ                       Utilization
    %   W   = 1/(μ - λ)                 Average time a customer spends in the system
    %   Wq  = λ/(μ*(μ-λ))               Average time a customer spends in the queue
    %   L   = λ * W OR λ/(μ-λ)          Average num. of customers in the system
    %   Lq  = λ * Wq                    Average num. of customers in the queue
    lambda = lambda_node_true(:);
    mu = mu_vec(:);
    rho = zeros(M,1);
    W = nan(M,1);
    Wq = nan(M,1);
    L = nan(M,1);
    Lq = nan(M,1);

    for m = 1:M
        if mu(m) > 0
            rho(m) = lambda(m) / mu(m);  % gets the actual utilization per node
        else
            rho(m) = NaN; % otherwise sets it to NaN
        end
        
        % another stability check. If rho is invalid, set all values to nan
        % and do not calculate delays
        if ~isfinite(rho(m)) || rho(m) <= 0 || rho(m) >= 1
            W(m)  = NaN;    
            Wq(m) = NaN;
            L(m)  = NaN;
            Lq(m) = NaN;
            continue;
        end

        % using little's law formulas (from above to populate the different
        % metrics
        W(m)  = 1 / (mu(m) - lambda(m)); 
        Wq(m) = lambda(m) / (mu(m) * (mu(m) - lambda(m)));
        L(m)  = lambda(m) * W(m);
        Lq(m) = lambda(m) * Wq(m);
    end

    disp('Avg.Time Spent at Nodes (Queue + Service):')
    disp(W);
    %disp('Avg. Time Spent Waiting in Queue:')
    %disp(Wq);
    %disp('Avg Number of Events in the M/M/1 System:')
    %disp(L);
    %disp('Avg,Number of Events in Queue:')
    %disp(Lq);

    % --- 7) Overall average wait+svc time ---
    % Cumulative sum of (arrival rate * average time of customer in system) divided by the total arrival rate
    %Lambda_total = sum(lambda);
    %if Lambda_total > 0
    %    avgDelay_theory = sum(lambda .* W) / Lambda_total;
    %else
    %    avgDelay_theory = NaN;
    %end

    % --- 8) Store results ---
    % Storing all the results in an array structure for easy access
    results = struct();
    results.params = struct('numSensors',numSensors,'commRadius',commRadius,...
                            'lambda_per_s',lambda_per_s,'rho_target',rho_target);
                            
    results.M                  = M;
    results.nearestNode        = nearestNode;
    results.n_per_node         = n_per_node;
    results.lambda_node_true   = lambda;
    results.mu_per_node        = mu;
    results.rho_per_node       = rho;
    results.W_per_node         = W;
    results.Wq_per_node        = Wq;
    results.L_per_node         = L;
    results.Lq_per_node        = Lq;
   


    figure("Name", 'CDF of Time Spent in System by an Event'); hold on;
    grid on; box on;
    tmin = 0.0;
    tmax = 9.0*W(1);
    Nt = 100;
    tax = linspace(tmin,tmax,Nt);

    cdfW = zeros(Nt,1);

    qcdfW = zeros(Nt,1);
    qcdfW = exp(-1.0*mu(1)*(1.0-rho).*tax);

    cdfW = 1.0 - qcdfW;

    %figure('CDF of Time Spent in System by an Event')
    plot(tax, cdfW, linewidth=4)
    title('CDF of Time Spent in System (W) by an event')
    xlabel('t'); ylabel('P(W \leq t)')
    ylim([0, 1.2])
    xlim([0 45])




    


    % (b) Summary: Expected arrivals per node from the results
    figure('Name','Theoretical Expected Arrivals per Node');
    bar(1:M, results.n_per_node, 'FaceAlpha', 0.8);
    grid on; box on;
    xlabel('Node'); ylabel('Number of Sensors');
    title('Number of Sensors Connected Per Node');
    xticks(1:M);

   
end 



% ---- All helper functions for the main function
% -----------------------------------------------


% ---HELPER FUNCTION 1) Builds the sensors network + nodes 
% --------------------------------------------------------------------
% Function to generate sensors around unit circle
function sensors = generate_sensors(numSensors, commRadius)
    sensors = struct();
    for i = 1:numSensors
        angle = 2*pi*rand();
        r = sqrt(rand());
        sensors(i).position = [r*cos(angle), r*sin(angle)];
        sensors(i).communicationRadius = commRadius;
    end
end


% Function to generate processing nodes at fixed angles inside circle
function processingNodes = generate_nodes()
    processingNodes = struct();
    angles_dg = [45, 135, 225, 315]; % proc nodes angles NOTE: can change to experiment with 
    r = 0.4; % radius of nodes / NOTE: change to experiment
    for i = 1:numel(angles_dg)
        processingNodes(i).position = [r * cosd(angles_dg(i)), r * sind(angles_dg(i))];
    end
end
% --------------------------------------------------------------------------


% --- HELPER FUNCTION --- 2) Find nearest node and assign sensors 
% ------------------------------------------------------------------
% Function to assign nearest in-range node
function nearestNode = assign_sensors_to_nodes(sensors, nodes)
    % reshape the sensor and nodes value to be in correct handling format
    sensorXY = reshape([sensors.position], 2, []).';
    nodeXY   = reshape([nodes.position],   2, []).';
    Ns = size(sensorXY,1);
    M  = size(nodeXY,1);

    % get distance 
    dx = sensorXY(:,1) - nodeXY(:,1)';   
    dy = sensorXY(:,2) - nodeXY(:,2)';   
    dist = sqrt(dx.^2 + dy.^2);
   
    commR = [sensors.communicationRadius]'; % obtain the communication radius from the input
    nearestNode = zeros(Ns,1); % set all to zeros, any that remain at 0 at the end are not assigned (0:blocked)
    for i = 1:Ns
        inRange = find(dist(i,:) <= commR(i)); % find logical mask where condition is true and set mask to node ID
        if isempty(inRange)
            nearestNode(i) = 0; % blocked (no nodes are in range)
        elseif numel(inRange) == 1
            nearestNode(i) = inRange; % only node in range, assign to that one
        else
            % if multiple in range, use euclidian distance to find closest node
            [~, k] = min(dist(i,inRange));
            nearestNode(i) = inRange(k);
        end
    end
end
% -------------------------------------------------------------------------


% --- HELPER FUNCTION --- Plot network sensor and nodes - Added t oinclude
% blocked sensors
% -------------------------------------------------------------------
% a) Function to plot the sensor network - Modified to include nodes 
function plot_network(sensors, nodes, nearestNode)
    % Create a new figure window for sensor network
    figure; hold on; box on; grid on;

    % ADDED to plot circle 
    points = [sensors.position];   
    val = reshape(points, 2, []).';
    num = numel(nodes);
    cmap = lines(num);
    angles_deg = [45, 135, 225, 315];

     for k = 1:num
        idx = (nearestNode == k);
        scatter(val(idx,1), val(idx,2), 24, cmap(k,:), 'filled', ...
                'DisplayName', sprintf('Node %d (%d^\\circ)', k, angles_deg(k)));
    end


    % Plot blocked sensors as hollowed circles (no node assigned, nearestNode==0)
    idxBlocked = (nearestNode == 0);
    if any(idxBlocked)
        scatter(val(idxBlocked,1), val(idxBlocked,2), 36, [0.8 0.8 0.8], 'filled', ...   % FIX: set color via 4th arg + 'filled'
            'Marker','o', ...                                                             % FIX: marker via name–value, not positional
            'MarkerEdgeColor',[0.6 0.6 0.6], ...
            'DisplayName','Blocked (no node)');                                           % FIX: proper name–value pair
    end

    % Plotting unit circle to see the boundary 
    theta = linspace(0, 2*pi, 400); %  angles from 0 to 2*pi
    radius = 1; % Set the radius to 1 for a unit circle
    x = radius * cos(theta); % x-coords
    y = radius * sin(theta); % y-coords

    plot(x, y); 

    % Plotting the nodes
    pts_nodes = [nodes.position];
    val_nodes = reshape(pts_nodes, 2, []).';
    %plot(val_nodes(:, 1), val_nodes(:, 2), 'kx', 'MarkerSize', 10);
    plot(val_nodes(:, 1), val_nodes(:, 2), '^', 'MarkerFaceColor','#90EE90', 'MarkerEdgeColor', '#90EE90', 'MarkerSize', 10);
    
    axis equal;
    title('Sensor Network');
    xlabel('X position');
    ylabel('Y position');

end
