# Knife Profitbricks

## DESCRIPTION:

This is a knife plugin to create, bootstrap and manage servers on the Profitbricks IaaS.

## INSTALLATION:

    gem install knife-profitbricks


## CONFIGURATION:

You need to provide you Profitbricks username and password, either add them to your knife.rb

    profitbricks_username = 'YOUR USERNAME'
    profitbricks_password = 'YOUR PASSWORD'

or store them in environment variables

    export PROFITBRICKS_USER=YOURUSERNAME
    export PROFITBRICKS_PASSWORD=YOURPASSWORd


## SUBCOMMANDS:

This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a ``--help`` flag

### knife profitbricks server initialize

Due to the specifics of the Profitbricks IaaS we first need to create an image which will be later used to provision new servers. You can specify the base image to be used, a user to create and your ssh public get.

### knife profitbricks server create

__beware__: this does not work properly yet  
Provisions a new server and then perform a Chef bootstrap (using the SSH protocol). The goal of the bootstrap is to get Chef installed
on the target system so it can run Chef Client with a Chef Server. 

### knife profitbricks server list

Outputs a list of all servers.

### knife profitbricks image list

Outputs a list of all images.

## LICENSE:

(The MIT License)

Copyright (c) 2013 Dominik Sander

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
