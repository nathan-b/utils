#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <list>
#include <thread>
#include <chrono>

#include <cstdint>

using namespace std;

struct stat_vals
{
	enum stat_label
	{
		USER,
		NICE,
		SYSTEM,
		IDLE,
		IOWAIT,
		IRQ,
		SOFTIRQ,
		STEAL,
		MAX
	};



	string label;
	uint64_t vals[stat_label::MAX];

	const string& get_label(int idx)
	{
		static string labels[stat_label::MAX] = 
		{
			"user",
			"nice",
			"system",
			"idle",
			"iowait",
			"irq",
			"softirq",
			"steal"
		};
	
		return labels[idx];
	}

	uint64_t get_total()
	{
		uint64_t ret = 0;
		for(int i = 0; i < stat_label::MAX; ++i)
		{
			ret += vals[i];
		}

		return ret;
	}

	stat_vals diff(const stat_vals& baseline)
	{
		stat_vals ret;
		ret.label = label + ":delta";
		for(int i = 0; i < stat_label::MAX; ++i)
		{
			ret.vals[i] = vals[i] - baseline.vals[i];
		}

		return ret;
	}

	string print()
	{
		stringstream ss;

		ss << label << " ";

		ss << "total: " << get_total() << "  ";

		for(int i = 0; i < stat_label::MAX; ++i)
		{
			ss << get_label(i) << ": " << vals[i] << "  ";
		}

		return ss.str();
	}

	friend istream& operator>>(istream& in, stat_vals& val);
};

istream& operator>>(istream& in, stat_vals& val)
{
	string line;

	getline(in, line);
	stringstream ss(line);

	ss >> val.label >> ws;

	for(int i = 0; i < stat_vals::stat_label::MAX; ++i)
	{
		ss >> val.vals[i] >> ws;
	}

	return in;
}

list<stat_vals> read_proc_stat()
{
	stat_vals row;
	list<stat_vals> ret;

	ifstream instr("/proc/stat");

	do 
	{
		instr >> row;
		if(row.label.rfind("cpu") == 0) 
		{
			ret.push_back(row);
		}
		else
		{
			break;
		}
	} while(instr);

	return ret;
}

int main(int argc, char** argv)
{
	auto statlist = read_proc_stat();
	auto last = statlist.front();
	while(true)
	{
		statlist = read_proc_stat();
		auto head = statlist.front();
		
		cout << head.diff(last).print() << endl;

		last = head;
		this_thread::sleep_for(chrono::seconds(1));
	}

	return 0;
}

