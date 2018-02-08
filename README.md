## flexemg: An EMG Gesture Recognition System with Flexible High-Density Sensors and Brain-Inspired High-Dimensional Classifier

This repository provides the dataset and MATLAB scripts used in [1]. It is publicly available under GNU General Public License v3.

### Repo structure
Note that all scripts are commented with function descriptions, input arguments, returns, etc.

- **`data/`**: Dataset containing raw EMG signals for 5 hand gestures from 3 subjects across multiple sessions. For more details check section IV.A (Generating Dataset) in the paper [1].
- **`funcs/`**: Contains internal functions for hyperdimensional computing.
- **`arraymap.mat`**: 16x4 matrix maps each electrode's physical position in the array to its corresponding channel index in the raw matrices.
- **`genfilter.m`**: Generates the filters used in preprocessing EMG signals.
- **`genheat.m`**: Generates a set of heatmaps for each gesture from a session (Figure 4b in the paper [1]).
- **`genlabels.m`**: Parses raw recording files to create data labels.
- **`getacc.m`**: Main function - trains and tests the HD classifier. 
- **`prefilter.mat`**: Saved filter coefficients from running `genfilter.m`.

### Sample usage

To find the classification accuracy for Subject 1 with N=5 (n-gram length) using 10 trials for training and data from all 64 channels, you can call `getacc` in the following way:

> `[out, correct, accs] = getacc(1, 5, 10, [1:64], './data/001-Session1Train/', './data/001-Session1Test/')`

### Problems?
If you face any problems or discover any bugs, please let us know: *MyLastName AT berkeley DOT edu*

For more info, you can read and cite our paper:

**[1] A. Moin, A. Zhou, A. Rahimi, S. Benatti, A. Menon, S. Tamakloe, J. Ting, N. Yamamoto, Y. Khan, F. Burghardt, L. Benini, A. Arias, and J. Rabaey, "An EMG Gesture Recognition System with Flexible High-Density Sensors and Brain-Inspired High-Dimensional Classifier," 2018 IEEE International Symposium on Circuits and Systems (ISCAS), Florence, Italy, 2017.**