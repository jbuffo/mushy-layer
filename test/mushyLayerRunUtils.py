import re
import os
import time
import math
import sys
import subprocess
import socket


def get_base_output_dir():
    #base_output_dir = '/home/parkinsonjl/mushy-layer/test/output/'
    base_output_dir = '/network/group/aopp/oceans/AW002_PARKINSON_MUSH/TestDiffusiveTimescale/'

    if not os.path.exists(base_output_dir):
        os.makedirs(base_output_dir)

    return base_output_dir


def get_matlab_base_command():
    parent_dir = os.path.abspath(os.pardir)
    matlab_folder = os.path.join(parent_dir, 'matlab', 'MethodsPaper')
    matlab_command = 'cd ' + matlab_folder + '; \n \n matlab -nodisplay -nosplash -nodesktop -r'

    return matlab_command


def get_current_vcs_revision():
    # For mercurial:
    # pipe = subprocess.Popen(
    #    ["hg", "identify", "--num"],
    #    stdout=subprocess.PIPE
    # )
    # repoVersion = pipe.stdout.read()
    # repoVersion = repoVersion.replace('\n', '')  # clean up a bit

    # For git:
    repo_version = subprocess.check_output(['git', 'rev-parse', 'HEAD'])

    return repo_version


def get_executable(base_name, dim=2):
    """ Given some program name, and assuming compilation options (mpiCC, gfortran, OPT, MPI etc.)
     return the correct executable for this system"""

    host = ''

    # If we're on gyre, append set host string to .GYRE
    hostname = socket.gethostname()
    if 'gyre' in hostname:
        host = '.GYRE'

    executable_name = '%s%dd.Linux.64.mpiCC.gfortran.OPT.MPI%s.ex' % (base_name, dim, host)

    return executable_name


def get_executable_name(exec_dir='', exec_name='mushyLayer2d'):
    """ Get the executable in MUSHY_LAYER_DIR/execSubcycle/ which contains mushyLayer2d,
     prioritising OPT over DEBUG compilations.
     Independent of the architecture (i.e. will find for different C++ compilers, fortran versions etc.) """

    if not exec_dir:
        mushy_layer_dir = os.environ['MUSHY_LAYER_DIR'] # previously: os.path.dirname(os.path.dirname(__file__))
        exec_dir = os.path.join(mushy_layer_dir, 'execSubcycle')

    # Get files in exec dir starting with mushyLayer2d and ending with ex
    possible_exec_files = [f for f in os.listdir(exec_dir) if f[:len(exec_name)] == exec_name and f[-2:] == 'ex']

    if len(possible_exec_files) == 0:
        print('Cannot find any executable files - have you compiled the code?')
        sys.exit(0)

    init_possible_exec_files = possible_exec_files

    # Remove/keep .GYRE in list as appropriate
    if 'gyre' in socket.gethostname():
        possible_exec_files = [f for f in possible_exec_files if 'GYRE' in f]
    else:
        possible_exec_files = [f for f in possible_exec_files if 'GYRE' not in f]

    if len(possible_exec_files) == 0:
        print('Cannot find any executable files that match the current system.')
        print('Executable founds: ' + '\n'.join(init_possible_exec_files))
        sys.exit(0)

    # Choose optimised execs over DEBUG execs as they will be quicker
    opthigh_exec = ''
    opt_exec = ''

    for f in possible_exec_files:
        if 'OPTHIGH' in f:
            opthigh_exec = f
        elif 'OPT' in f:
            opt_exec = f

    if opthigh_exec:
        exec_file = opthigh_exec
    elif opt_exec:
        exec_file = opt_exec
    else:
        exec_file = possible_exec_files[1]


    # Can also specify the file manually
    # exec = 'mushyLayer2d.Linux.64.mpiCC.gfortran.OPT.MPI.ex'

    # Sanity check
    if not os.path.exists(os.path.join(exec_dir, exec_file)):
        print('Executable ' + exec_file +' not found in directory ' + exec_dir)
        sys.exit(0)

    return exec_file


def construct_run_name(params):
    # run_name = 'CR' + str(params['parameters.compositionRatio']) + 'RaC' + str(params['parameters.rayleighComp'])

    long_to_short_name = {'parameters.compositionRatio': 'CR',
                          'parameters.rayleighComp': 'RaC',
                          'parameters.lewis': 'Le',
                          'parameters.darcy': 'Da',
                          'parameters.nonDimReluctance': 'R',
                          'parameters.bottomEnthalpy': 'HBottom'}

    params_to_include = ['parameters.compositionRatio',
                         'parameters.rayleighComp',
                         'parameters.lewis',
                         'parameters.permeabilityFunction']

    param_format = {'parameters.compositionRatio': '%1.3f',
                    'parameters.lewis': '%d',
                    'parameters.darcy': '%.1e',
                    'parameters.nonDimReluctance': '%.1e',
                    'parameters.bottomEnthalpy': '%1.2f'}
                       
    if 'parameters.rayleighComp' in params:
        if float(params['parameters.rayleighComp']) > 1000:
            param_format['parameters.rayleighComp'] = '%.1e'
        else:
            param_format['parameters.rayleighComp'] = '%d'

    permeability_functions = ['UniformPermeability',
                             'ChiCubedPermeability',
                             'KozenyPermeability',
                             'LogPermeability',
                             'CustomPermeability']

    run_name = ''

    for p in params_to_include:
        if p in long_to_short_name.keys() and p in params:
            run_name = run_name + long_to_short_name[p] + param_format[p] % float(params[p])
        elif p == 'parameters.permeabilityFunction' and p in params:
            perm_func = int(params[p])
            run_name = run_name + permeability_functions[perm_func]
        else:
            # Don't know how to handle this. Just do nothing.
            pass
            
    if float(params['parameters.darcy']) > 0:
            run_name = run_name + long_to_short_name['parameters.darcy'] + param_format['parameters.darcy'] % float(params['parameters.darcy'])
            run_name = run_name + long_to_short_name['parameters.nonDimReluctance'] + param_format['parameters.nonDimReluctance'] % float(params['parameters.nonDimReluctance'])

    # params which don't follow the same format

    # if we're using a sponge
    if ('main.spongeHeight' in params 
        and 'main.spongeRelaxationCoeff' in params
        and float(params['main.spongeHeight']) > 0.0
        and float(params['main.spongeRelaxationCoeff']) > 0.0):
        run_name = run_name + '_sponge_'

    # grid resolution
    cells =params['main.num_cells'].split(' ')
    grid_res = int(cells[0])
    run_name = run_name + "pts" + str(grid_res)

        
    return run_name


def read_inputs(inputs_file):
    """ Load up an inputs file and parse it into a dictionary """

    params = {}

    # Read in the file
    file_data = None
    with open(inputs_file, 'r') as f:
        file_data = f.readlines()

    for line in file_data:
        # print(line)
        # Ignore lines that are commented out
        if line.startswith('#'):
            continue

        # Remove anything after a #
        line = re.sub('#[^\n]*[\n]', '', line)

        parts = line.split('=')
        if len(parts) > 1:
            key = parts[0].strip()
            val = parts[1].strip()
            params[key] = val

    # print(params)
    return params


def write_inputs(location, params, ignore_list = None, doSort=True):
    output_file = ''

    key_list = params.keys()
    if doSort:
        key_list.sort()
    
    for key in key_list:
        if not ignore_list or key not in ignore_list:
            
            if isinstance(params[key], list):
                key_val = ' '.join([str(a) for a in params[key]])
                
            else:
                key_val = str(params[key])

            output_file = output_file + '\n' + \
                key + '=' + key_val

    with open(location, 'w') as f:
        f.write(output_file)


def has_reached_steady_state(folder):
    time_table_file = os.path.join(folder, 'time.table.0')

    if os.path.exists(time_table_file):
        return True
        

def time_since_folder_updated(directory):
    smallest_t = 1e100
    for filename in os.listdir(directory):
        this_time_diff = time_since_file_updated(os.path.join(directory, filename))
        smallest_t = min(smallest_t, this_time_diff)
        
    return smallest_t


def time_since_file_updated(filename):
    current_t = time.time()
    t = os.path.getmtime(filename)
        
    this_time_diff = abs(current_t - t)
    
    return this_time_diff
    
def get_restart_file(most_recent_path):

    restart_file = ''
    
    chk_files = [f for f in os.listdir(most_recent_path) if len(f) > 4 and f[:3] == 'chk']
    
    # print('Chk files in ' + most_recent_path + ': ')
    # print(chk_files)

    if len(chk_files) > 0:
        restart_file = chk_files[-1]
        
    print('Found ' + str(len(chk_files)) + ' checkpoint files, most recent: ' + restart_file)

    return restart_file


def get_final_plot_file(directory):
    files_dir = [f for f in os.listdir(directory)  if (os.path.isfile(os.path.join(directory, f))) ]
    plt_files = []
    # print(files_dir)
    for f in files_dir:
        # print(f)
        # print(f[-5:])
        if len(f) > 5 and not 'chk' in f and f[-5:] == '.hdf5':
            plt_files.append(f)

    plt_files = sorted(plt_files)

    if plt_files:
        return plt_files[-1]
    else:
        return None


def get_final_chk_file(directory):
    files_dir = [f for f in os.listdir(directory)  if (os.path.isfile(os.path.join(directory, f))) ]
    plt_files = []
    # print(files_dir)
    for f in files_dir:
        # print(f)
        # print(f[-5:])
        if len(f) > 5 and 'chk' in f and f[-5:] == '.hdf5':
            plt_files.append(f)

    plt_files = sorted(plt_files)

    if plt_files:
        return plt_files[-1]
    else:
        return None


def is_power_of_two(n):
    test = math.log(n)/math.log(2)
    
    if round(test) == test:
        return True
    else:
        return False


def string_to_array(string):

    if isinstance(string, list):
        return string

    parts = string.split(' ')
    array = [int(i) for i in parts]
    return array


def array_to_string(array):
    str_array = [str(a) for a in array]
    string = ' '.join(str_array)
    return string


def chombo_compare_analysis(data_folder, nz_uniform, uniform_prefix):
    '''
    Create inputs files and run them for doing chombo compare on all simulations in this directory
    '''
    chombo_dir = os.environ['CHOMBO_HOME']
    compare_dir = os.path.join(chombo_dir, 'lib', 'util', 'ChomboCompare')
    compare_exec = get_executable_name(compare_dir, 'compare2d')
    compare_exec = os.path.join(compare_dir, compare_exec)
    print('Found executable %s ' % compare_exec)

    all_folders = [x for x in os.listdir(data_folder) if os.path.isdir(os.path.join(data_folder,x))]
    # print(all_folders)
    # Firstly compute richardson errors
    uniform_folders = [x for x in all_folders if 'Uniform' in x]
    uniform_folders = sorted(uniform_folders)
    print(uniform_folders)


    finest_resolution = uniform_folders[-1]
    uniform_folders = uniform_folders[:-1]

    exact_file = get_final_plot_file(os.path.join(data_folder, finest_resolution))

    for i in range(0, len(uniform_folders)-1):
        # for run_folder in uniform_folders:
        this_folder = os.path.join(data_folder, uniform_folders[i])
        next_folder = os.path.join(data_folder, uniform_folders[i+1])

        compare_params_file = os.path.join(this_folder, 'compare-richardson.inputs')
        error_file = os.path.join(this_folder, 'err-richardson.2d.hdf5')
        computed_file = os.path.join(this_folder, get_final_plot_file(this_folder))

        exact_file = os.path.join(next_folder, get_final_plot_file(next_folder))

        compare_params = {'compare.sameSize':  0,
                            'compare.exactRoot': exact_file,
                            'compare.computedRoot' : computed_file,
                            'compare.errorRoot' : error_file,
                            'compare.doPlots' : 1,
                            'compare.HOaverage':  0}

        write_inputs(compare_params_file, compare_params)

        cmd = 'cd %s \n %s %s \n \n' % (this_folder, compare_exec, compare_params_file)
        print(cmd)
        os.system(cmd)



    return ''

