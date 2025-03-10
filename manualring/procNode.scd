(
  s.boot;
)

(
    p = SynthDef(\slider, {
        |gain = 0.5, delay = 0.5|
        var input = SoundIn.ar(0);
        var processed = DelayC.ar(input, 2, delay, gain);
        Out.ar(0, processed);


}).add;
)

(
p = Synth(\slider, [\gain, 0, \delay, 0]);
)


(
var win, slider, x, y;

win= Window("2D Slider", Rect(200, 200, 300, 300)).front;

slider = Slider2D(win, Rect(20,20,260,260)).action_({

        x = slider.x * 2;
        y = slider.y * 0.8;

        p.set(\delay, x, \gain, y);
})


)




