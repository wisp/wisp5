WISP 5
====

Welcome to the WISP5 firmware repository!

Got questions? Check out the tutorials and discussion board at: http://wisp5.wikispaces.com

Schematics for the WISP5 prototype are available here: http://wisp5.wikispaces.com/WISP+Hardware

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

 * **accelDemo** An application which references wisp-base and demonstrates sampling of the accelerometer and returning acceleration data to the reader through fields of the EPC.

2. Build wisp-base and then the two applications.

3. Program and run your WISP5 with run-once, and wait for LED to pulse to indicate completion.

4. Program and run your WISP5 with simpleAckDemo and ensure that it can communicate with the reader. Use an Impinj Speedway series reader with Tari = 6.25us or 7.14us, link frequency = 640kHz, and reverse modulation type = FM0.

A summary of protocol details is given below.

Protocol summary
----

Delimiter = 12.5us

Tari = 6.25us

Link Frequency (T=>R) = 640kHz

Divide Ratio (DR) = 64/3

Reverse modulation type = FM0

RTCal (R=>T) = Nominally 15.625us (2.5*Data-0), Appears to accept 12.5us to 18.75us

TRCal (R=>T) = Appears to accept 13.75us to 56.25us, reader usage of this field may vary.

Data-0 (R=>T) = 6.25us

PW (R=>T) = 3.125us (0.5*(Data-0))

Enjoy the WISP5, and please contribute your comments and bugfixes here!


