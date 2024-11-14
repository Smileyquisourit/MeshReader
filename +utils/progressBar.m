function progressBar(act,tot,options)
    %PROGRESSEBAR Print a progress bar and actualize it.
    %   Print a progress bar and actualize it be using the '\b' caracter.
    % Nothing must be printed on the console in the same time.

    arguments (Input)
        act (1,1) double
        tot (1,1) double

        options.bar_len (1,1) double = 20
        options.title   (1,1) string = "Progression"
        options.init    (1,1) logical = false
    end
    

    persistent to_erase;

    % Determination de la barre :
    % ---------------------------
    progress = act/tot;
    if options.init ; to_erase = 0; end
    bar = options.title + " : [%-*s] (%05.2f/100)";

    % Création :
    % ----------
    bar = sprintf(bar, options.bar_len, repmat('#',1,round(progress*options.bar_len)), progress*100);
    to_print = backSpace(to_erase) + bar;
    to_erase = length(char(bar));

    fprintf(to_print)
 
end

function to_print = backSpace(n)
    to_print = "";
    if n ~= 0
        for i = 1:1:n
            to_print = to_print+"\b";
        end
    end
end
