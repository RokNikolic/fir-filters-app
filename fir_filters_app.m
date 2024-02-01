classdef fir_filters_app < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        Panel_3                matlab.ui.container.Panel
        SignalAxes             matlab.ui.control.UIAxes
        Panel_2                matlab.ui.container.Panel
        FilterAxes             matlab.ui.control.UIAxes
        Panel                  matlab.ui.container.Panel
        SaveSignalButton       matlab.ui.control.Button
        ChannelsDropDown       matlab.ui.control.DropDown
        ChannelsDropDownLabel  matlab.ui.control.Label
        LoadSignalButton       matlab.ui.control.Button
        FilterControlsPanel    matlab.ui.container.Panel
        OrderKnob              matlab.ui.control.Knob
        OrderKnobLabel         matlab.ui.control.Label
        HighcutoffKnob         matlab.ui.control.Knob
        HighcutoffKnobLabel    matlab.ui.control.Label
        LowcutoffKnob          matlab.ui.control.Knob
        LowcutoffKnobLabel     matlab.ui.control.Label
        FiltersButtonGroup     matlab.ui.container.ButtonGroup
        BandstopButton         matlab.ui.control.RadioButton
        BandpassButton         matlab.ui.control.RadioButton
        HighpassButton         matlab.ui.control.RadioButton
        LowpassButton          matlab.ui.control.RadioButton
        NoneButton             matlab.ui.control.RadioButton
    end

    
    properties (Access = private)
        Eeg
        Tm
        CurrentSignal
        FilteredSignal
        FilterType
        Fs
        LowCutoff
        HighCutoff
        Order
    end
    
    methods (Access = private)
        
        function displaySignals(app)
            plot(app.SignalAxes, app.Tm, app.CurrentSignal, 'b')
            hold(app.SignalAxes, "on")
            plot(app.SignalAxes, app.Tm, app.FilteredSignal, 'g')
            hold(app.SignalAxes, "off")
        end
        
        function [filtered_signal] = getFilterCoefficients(app, order, lowFreq, highFreq, type)
            if type == "lowpass"
                frequencies = [0, highFreq, highFreq, app.Fs/2]/(app.Fs/2);
                responces = [1, 1, 0, 0];
            elseif type == "highpass"
                frequencies = [0, lowFreq, lowFreq, app.Fs/2]/(app.Fs/2);
                responces = [0, 0, 1, 1];
            elseif type == "bandpass"
                if highFreq < lowFreq
                    highFreq = lowFreq + 1;
                end
                frequencies = [0, lowFreq, lowFreq, highFreq, highFreq, app.Fs/2]/(app.Fs/2);
                responces = [0, 0, 1, 1, 0, 0];
            elseif type == "bandstop"
                if highFreq < lowFreq
                    highFreq = lowFreq + 1;
                end
                frequencies = [0, lowFreq, lowFreq, highFreq, highFreq, app.Fs/2]/(app.Fs/2);
                responces = [1, 1, 0, 0, 1, 1];
            else
                disp("Error in filter choise")
                frequencies = [0, app.Fs/2, app.Fs/2, app.Fs/2]/(app.Fs/2);
                responces = [1, 1, 0, 0];
            end
            coefficients = firls(order, frequencies, responces);
            [magRes, ~] = freqz(coefficients, 1, 1024);
            plot(app.FilterAxes, abs(magRes), 'm')
            filtered_signal = filter(coefficients, 1, app.CurrentSignal);
        end
        
        
        function UpdateFilter(app)
            if app.FilterType == "None"
                displaySignals(app);
            elseif app.FilterType == "Low pass"
                app.FilteredSignal = getFilterCoefficients(app, app.Order, app.LowCutoff, app.HighCutoff, "lowpass");
                displaySignals(app);
            elseif app.FilterType == "High pass"
                app.FilteredSignal = getFilterCoefficients(app, app.Order, app.LowCutoff, app.HighCutoff, "highpass");
                displaySignals(app);
            elseif app.FilterType == "Band pass"
                app.FilteredSignal = getFilterCoefficients(app, app.Order, app.LowCutoff, app.HighCutoff, "bandpass");
                displaySignals(app);
            elseif app.FilterType == "Band stop"
                app.FilteredSignal = getFilterCoefficients(app, app.Order, app.LowCutoff, app.HighCutoff, "bandstop");
                displaySignals(app);
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: LoadSignalButton
        function LoadSignalButtonPushed(app, event)
            [file_name, file_path] = uigetfile({'*.edf'}, 'Select signal for proccesing', pwd);
            if isequal(file_name, 0)
                disp("Please chose file")
            else
                relative_path = relativepath(file_path); % find a funtion for getting the relative path
                final_name = fullfile(relative_path, file_name);
                [eeg, samp_freq, tm] = rdsamp(final_name, 1:64);
                app.Eeg = eeg;
                app.Fs = samp_freq;
                app.Tm = tm;

                app.CurrentSignal = eeg;
                app.FilteredSignal = zeros(1, length(eeg));
                displaySignals(app);

                app.LowCutoff = 0;
                app.HighCutoff = samp_freq/2;
                app.Order = 100;

                app.ChannelsDropDown.Enable = "on";
                app.FiltersButtonGroup.Enable = "on";
                app.SaveSignalButton.Enable = "on";
            end
        end

        % Value changed function: ChannelsDropDown
        function ChannelsDropDownValueChanged(app, event)
            value = app.ChannelsDropDown.Value;
            if value == "All"
                app.CurrentSignal = app.Eeg;
                displaySignals(app);
            else
                current_signal = app.Eeg(:, value);
                app.CurrentSignal = current_signal;
                displaySignals(app);
            end
        end

        % Selection changed function: FiltersButtonGroup
        function FiltersButtonGroupSelectionChanged(app, event)
            selectedButton = app.FiltersButtonGroup.SelectedObject;
            app.FilterType = selectedButton.Text;
            if app.FilterType == "None"
                app.LowcutoffKnob.Enable = "off";
                app.HighcutoffKnob.Enable = "off";
                app.OrderKnob.Enable = "off";
            else
                app.LowcutoffKnob.Enable = "on";
                app.HighcutoffKnob.Enable = "on";
                app.OrderKnob.Enable = "on";
            end
            UpdateFilter(app);
        end

        % Value changing function: LowcutoffKnob
        function LowcutoffKnobValueChanging(app, event)
            changingValue = event.Value;
            app.LowCutoff = changingValue;
            UpdateFilter(app);
        end

        % Value changing function: HighcutoffKnob
        function HighcutoffKnobValueChanging(app, event)
            changingValue = event.Value;
            app.HighCutoff = changingValue;
            UpdateFilter(app);
        end

        % Value changing function: OrderKnob
        function OrderKnobValueChanging(app, event)
            changingValue = event.Value;
            app.Order = floor(changingValue/2)*2;
            UpdateFilter(app);
        end

        % Button pushed function: SaveSignalButton
        function SaveSignalButtonPushed(app, event)
            writematrix(app.CurrentSignal, 'output.txt')
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1017 562];
            app.UIFigure.Name = 'MATLAB App';

            % Create FiltersButtonGroup
            app.FiltersButtonGroup = uibuttongroup(app.UIFigure);
            app.FiltersButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @FiltersButtonGroupSelectionChanged, true);
            app.FiltersButtonGroup.Enable = 'off';
            app.FiltersButtonGroup.Title = 'Filters';
            app.FiltersButtonGroup.FontWeight = 'bold';
            app.FiltersButtonGroup.Position = [18 14 123 202];

            % Create NoneButton
            app.NoneButton = uiradiobutton(app.FiltersButtonGroup);
            app.NoneButton.Text = 'None';
            app.NoneButton.Position = [11 156 51 22];
            app.NoneButton.Value = true;

            % Create LowpassButton
            app.LowpassButton = uiradiobutton(app.FiltersButtonGroup);
            app.LowpassButton.Text = 'Low pass';
            app.LowpassButton.Position = [11 131 73 22];

            % Create HighpassButton
            app.HighpassButton = uiradiobutton(app.FiltersButtonGroup);
            app.HighpassButton.Text = 'High pass';
            app.HighpassButton.Position = [11 106 75 22];

            % Create BandpassButton
            app.BandpassButton = uiradiobutton(app.FiltersButtonGroup);
            app.BandpassButton.Text = 'Band pass';
            app.BandpassButton.Position = [11 82 79 22];

            % Create BandstopButton
            app.BandstopButton = uiradiobutton(app.FiltersButtonGroup);
            app.BandstopButton.Text = 'Band stop';
            app.BandstopButton.Position = [11 56 76 22];

            % Create FilterControlsPanel
            app.FilterControlsPanel = uipanel(app.UIFigure);
            app.FilterControlsPanel.Title = 'Filter Controls';
            app.FilterControlsPanel.FontWeight = 'bold';
            app.FilterControlsPanel.Position = [157 14 400 202];

            % Create LowcutoffKnobLabel
            app.LowcutoffKnobLabel = uilabel(app.FilterControlsPanel);
            app.LowcutoffKnobLabel.HorizontalAlignment = 'center';
            app.LowcutoffKnobLabel.FontWeight = 'bold';
            app.LowcutoffKnobLabel.Position = [41 34 66 22];
            app.LowcutoffKnobLabel.Text = 'Low cutoff';

            % Create LowcutoffKnob
            app.LowcutoffKnob = uiknob(app.FilterControlsPanel, 'continuous');
            app.LowcutoffKnob.Limits = [1 79];
            app.LowcutoffKnob.ValueChangingFcn = createCallbackFcn(app, @LowcutoffKnobValueChanging, true);
            app.LowcutoffKnob.Enable = 'off';
            app.LowcutoffKnob.Position = [42 90 60 60];
            app.LowcutoffKnob.Value = 1;

            % Create HighcutoffKnobLabel
            app.HighcutoffKnobLabel = uilabel(app.FilterControlsPanel);
            app.HighcutoffKnobLabel.HorizontalAlignment = 'center';
            app.HighcutoffKnobLabel.FontWeight = 'bold';
            app.HighcutoffKnobLabel.Position = [165 35 68 22];
            app.HighcutoffKnobLabel.Text = 'High cutoff';

            % Create HighcutoffKnob
            app.HighcutoffKnob = uiknob(app.FilterControlsPanel, 'continuous');
            app.HighcutoffKnob.Limits = [1 79];
            app.HighcutoffKnob.ValueChangingFcn = createCallbackFcn(app, @HighcutoffKnobValueChanging, true);
            app.HighcutoffKnob.Enable = 'off';
            app.HighcutoffKnob.Position = [167 89 60 60];
            app.HighcutoffKnob.Value = 1;

            % Create OrderKnobLabel
            app.OrderKnobLabel = uilabel(app.FilterControlsPanel);
            app.OrderKnobLabel.HorizontalAlignment = 'center';
            app.OrderKnobLabel.FontWeight = 'bold';
            app.OrderKnobLabel.Position = [306 35 38 22];
            app.OrderKnobLabel.Text = 'Order';

            % Create OrderKnob
            app.OrderKnob = uiknob(app.FilterControlsPanel, 'continuous');
            app.OrderKnob.Limits = [2 500];
            app.OrderKnob.ValueChangingFcn = createCallbackFcn(app, @OrderKnobValueChanging, true);
            app.OrderKnob.Enable = 'off';
            app.OrderKnob.Position = [293 91 60 60];
            app.OrderKnob.Value = 2;

            % Create Panel
            app.Panel = uipanel(app.UIFigure);
            app.Panel.Position = [16 503 986 48];

            % Create LoadSignalButton
            app.LoadSignalButton = uibutton(app.Panel, 'push');
            app.LoadSignalButton.ButtonPushedFcn = createCallbackFcn(app, @LoadSignalButtonPushed, true);
            app.LoadSignalButton.FontSize = 14;
            app.LoadSignalButton.Position = [15 11 100 25];
            app.LoadSignalButton.Text = 'Load signal';

            % Create ChannelsDropDownLabel
            app.ChannelsDropDownLabel = uilabel(app.Panel);
            app.ChannelsDropDownLabel.HorizontalAlignment = 'right';
            app.ChannelsDropDownLabel.FontWeight = 'bold';
            app.ChannelsDropDownLabel.Position = [133 12 59 22];
            app.ChannelsDropDownLabel.Text = 'Channels';

            % Create ChannelsDropDown
            app.ChannelsDropDown = uidropdown(app.Panel);
            app.ChannelsDropDown.Items = {'All', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46', '47', '48', '49', '50', '51', '52', '53', '54', '55', '56', '57', '58', '59', '60', '61', '62', '63', '64'};
            app.ChannelsDropDown.ValueChangedFcn = createCallbackFcn(app, @ChannelsDropDownValueChanged, true);
            app.ChannelsDropDown.Enable = 'off';
            app.ChannelsDropDown.Position = [207 12 100 22];
            app.ChannelsDropDown.Value = 'All';

            % Create SaveSignalButton
            app.SaveSignalButton = uibutton(app.Panel, 'push');
            app.SaveSignalButton.ButtonPushedFcn = createCallbackFcn(app, @SaveSignalButtonPushed, true);
            app.SaveSignalButton.FontSize = 14;
            app.SaveSignalButton.Enable = 'off';
            app.SaveSignalButton.Position = [868 11 100 25];
            app.SaveSignalButton.Text = 'Save signal';

            % Create Panel_2
            app.Panel_2 = uipanel(app.UIFigure);
            app.Panel_2.Position = [574 14 428 202];

            % Create FilterAxes
            app.FilterAxes = uiaxes(app.Panel_2);
            title(app.FilterAxes, 'Filter respone')
            xlabel(app.FilterAxes, 'Frequency')
            ylabel(app.FilterAxes, 'Amplitude')
            zlabel(app.FilterAxes, 'Z')
            app.FilterAxes.Position = [8 9 412 185];

            % Create Panel_3
            app.Panel_3 = uipanel(app.UIFigure);
            app.Panel_3.Position = [16 232 986 256];

            % Create SignalAxes
            app.SignalAxes = uiaxes(app.Panel_3);
            title(app.SignalAxes, 'Signal')
            xlabel(app.SignalAxes, 'Time')
            ylabel(app.SignalAxes, 'Amplitude')
            zlabel(app.SignalAxes, 'Z')
            app.SignalAxes.Position = [6 8 972 242];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = fir_filters_app

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end