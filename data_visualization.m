function data_visualization(data, plottype, xlbl, ylbl, ttl)
    % assume data is 1D array
    arguments
        data double
        plottype string % = "scatter"
        xlbl string = "x" % default value if not given
        ylbl string = "y" % default value if not given
        ttl string = "plot" % default value if not given
    end
    try
        if ~any(isnan(data))
            if plottype == "bar"
                disp("DEBUG LOG: bar plot")
                figure;
                bar(data)

            elseif plottype == "hist"
                disp("DEBUG LOG: histogram")
                figure;
                histogram(data)

            elseif plottype == "scatter"
                disp("DEBUG LOG: scatter plot")
                dataM = reshape(data, 2, length(data)/2)';
                figure;
                scatter(dataM(:,1), dataM(:,2))
                hold on
                % plot circular boundary
                theta = linspace(0, 2*pi, 100);
                x = cos(theta);
                y = sin(theta);
                plot(x, y, 'r--');
                axis equal;
                hold off

            elseif plottype == "plot2"
                disp("DEBUG LOG: 2d plot")
                dataM = reshape(data, 2, length(data)/2)';
                figure;
                plot(dataM(:,1), dataM(:,2))

            else
                disp("DEBUG LOG: invalid plottype")
                return;
            end
           
            title(ttl);
            xlabel(xlbl);
            ylabel(ylbl);
        end
    catch ME
        disp(['MATLAB Error: ', ME.message]);
    end
end
