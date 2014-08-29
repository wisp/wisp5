WISP 5
====

Welcome to the WISP5 firmware repository!

Schematics for the WISP5 prototype are temporarily available here: 
http://sensor.cs.washington.edu/wisp5/wisp5-schem.pdf

Interested in building a host-side application to talk with WISPs? Look no further than the SLLURP library for configuring LLRP-based RFID readers:
https://github.com/ransford/sllurp

Important Notices
----
Please note that the MSP430FR5969 included on the WISP 5 is not compatible with TI Code Composer Studio versions prior to version 6. Please use CCS v6 or above.

The WISP 5 is intended to be compatible with Impinj Speedway and Impinj Speedway Revolution series FCC-compliant readers. For updates about compatibility with other readers, please contact the developers.

Configuration
----
1. Set your Code Composer Studio v6x workspace to wisp5/ccs and import the following projects:

 * **wisp-base** The standard library for the WISP5. Compiled as a static library.
 * **run-once** An application which generates a table of random numbers and stores them to non-volatile memory on the WISP, for use in slotting protocol and unique identification.

 * **simpleAckDemo** An application which references wisp-base and demonstrates basic communication with an RFID reader.

2. Build wisp-base and then the two applications.

3. Program and run your WISP5 with run-once, and wait for LED to pulse to indicate completion.

4. Program and run your WISP5 with simpleAckDemo and ensure that it can communicate with the reader. Use an Impinj Speedway series reader with Tari = 12.5us, link frequency = 160kHz, and reverse modulation type = FM0.

Enjoy the WISP5, and please contribute your comments and bugfixes here!


