function [sensorsPos, communicationCount, receivedEventCount, averageDelay, delays] = WSN_BB1_SysML(numSensors, communicationRadius, numEvents)    
    if nargin < 3
        % if all required inputs parameters aren't given, return NaN for
        % outputs parameters
        sensorsPos = NaN;
        communicationCount = NaN;
        receivedEventCount = NaN;
        averageDelay = NaN;
        delays = NaN;
    else
        % inputs parameters:
        % numSensors: Total number of sensors in the network
        % communicationRadius: Radius of communication for each sensor
        % numEvents: Total number of events in the simulation
    
        % Validate input parameters
        assert(numSensors > 0, 'numSensors should be a positive number.');
        assert(communicationRadius > 0, 'communicationRadius should be a positive number.');
        assert(numEvents > 0, 'numEvents should be a positive number.');
    
    
        % Generate sensor network
        sensors = generateSensorNetwork(numSensors, communicationRadius);
        sensorsPos = [sensors.position]; % convert this to an array
    
        % Generate events
        events = generateEvents(numEvents, numSensors);
    
        % Process events
        [communicationCount, receivedEventCount, averageDelay, delays] = processEvents(sensors, events, numEvents);
    end
end


% Function to generate sensor network
function sensors = generateSensorNetwork(numSensors, communicationRadius)
    % Initialize sensors as struct array with position and communication radius
    sensors = struct();

    % Circle parameters (unit circle in center of 1x1 plot)
    cx = 0.0; % center x
    cy = 0.0; % center y
    R = 1.0; % radius of circular region

    % Assign random positions and communication radius to each sensor
    for i = 1:numSensors
        r = R * sqrt(rand());          % radial distance
        theta = 2 * pi * rand();       % angle
        x = cx + r * cos(theta);       % x-coordinate
        y = cy + r * sin(theta);       % y-coordinate
        
        sensors(i).position = [x, y];
        sensors(i).communicationRadius = communicationRadius;
    end
end


% Function to generate events
function events = generateEvents(numEvents, numSensors)
    % Initialize events as struct array with timestamp and sensorID
    events = struct();

    % Assign random timestamps and sensor IDs to each event
    for i = 1:numEvents
        events(i).timestamp = rand();  % also unif distrib 0,1;  test with Poisson etc.. 
        events(i).sensorID = randi([1, numSensors]); % select sensors at random to correspond to events
    end

    % Sort events by timestamp
    [~, order] = sort([events.timestamp]);
    events = events(order);
end


% Function to process events
function [communicationCount, receivedEventCount, averageDelay, delays] = processEvents(sensors, events, numEvents)
    % Initialize the array 'communicationCount' with zeros; its length is equal to the number of sensors.
    % This array will keep track of how many times each sensor communicates.
    communicationCount = zeros(1, length(sensors)); 
    receivedEventCount = zeros(1, length(sensors));

    % Initialize the array 'delays' with zeros; its length is a safe upper bound estimate (numEvents * numSensors).
    % This array will store the delay for each communication between sensors.
    delays = zeros(1, numEvents * length(sensors));

    % Initialize 'idx' to 1; this variable will keep track of our current position in the 'delays' array.
    idx = 1;

    % For each event in the 'events' array
    for i = 1:length(events)
        % Increment the communication count for the sensor associated with the current event
        communicationCount(events(i).sensorID) = communicationCount(events(i).sensorID) + 1; 

        % For each sensor in the 'sensors' array
        for j = 1:length(sensors) 
            % If the current sensor is not the one associated with the current event and is within the communication radius of the sensor associated with the event
            if j ~= events(i).sensorID && norm(sensors(j).position - sensors(events(i).sensorID).position) <= sensors(events(i).sensorID).communicationRadius
                % Calculate the communication delay. It's proportional to the distance between the two sensors and inversely proportional to the communication radius.
                delay = norm(sensors(j).position - sensors(events(i).sensorID).position) / sensors(events(i).sensorID).communicationRadius;
                receivedEventCount(j) = receivedEventCount(j) + 1;

                % Store the calculated delay in the 'delays' array and increment 'idx'
                delays(idx) = delay;
                idx = idx + 1;
            end
        end
    end

    % Trim the 'delays' array to remove unused space
    delays = delays(1:(idx-1));

    % Calculate the average communication delay by taking the mean of the 'delays' array
    averageDelay = mean(delays);
end
