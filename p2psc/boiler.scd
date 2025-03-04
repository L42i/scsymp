//STEP 1: RUN LOCAL AUDIO SERVER
(
s.boot;
s.meter;
)


//STEP 2: RECEIVER
(
fork {
	p = P2PSC();
	p.sync;
	p.setName("Orlando"); // set your name accordingly
	p.sync;
	p.addPath({ |msg|
		var sleeptime = 1;
		var freq = 200;

		msg.postln; //print message for debugging

		{SinOsc.ar(freq:freq)*0.5*EnvGen.kr(Env.perc(releaseTime:sleeptime-0.01), doneAction:2)}.play;


		fork {
			sleeptime.wait; // wait for one second
            peer = "Ishaan";
            ("Sending initial ping to:"+peer).postln;
            ("/"++peer++"/ping").postln;

            p.sendMsg("/"++peer++"/ping" , p.name)
		};
	},"/ping");
}
)


// STEP 3: SENDER
(
fork {
    peer = "Ishaan";
    ("Sending initial ping to:"+peer).postln;
    ("/"++peer++"/ping").postln;

    p.sendMsg("/"++peer++"/ping" , p.name)

    
}
)