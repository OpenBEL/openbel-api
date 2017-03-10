#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Usage:  program.py <customer>

"""


import requests
import json
import os.path

base_url = "http://localhost:9292"

files = [
  f"{os.path.dirname(__file__)}/bel2.0-example-statements.bel",
  f"{os.path.dirname(__file__)}/bel2_document_examples.bel"
]

def send_request(bel):
    # Issue #134
    # GET http://localhost:9292/api/expressions/rxn(reactants(a(CHEBI:superoxide)),products(a(CHEBI:%22hydrogen%20peroxide%22),%20a(CHEBI:%20%22oxygen%22))/validation

    try:
        response = requests.get(
            url=f"{base_url}/api/expressions/{bel}/validation",
        )
        try:
            r = response.json()
        except:
            r = None

        # print(f"Status {response.status_code}  Response: {r}")
        return (response.status_code, r)

    except requests.exceptions.RequestException:
        # return (response.status_code, response.json())
        print(f"Error {response.status_code}, {bel}")


def run_examples():
    results = []
    cnt = error_cnt = success_cnt = 0
    for fn in files:
        with open(fn, 'r') as f:
            for bel in f:
                cnt += 1
                bel = bel.strip()

                print(f"Running bel: {bel}")

                (status, msg) = send_request(bel)
                if status != 200:
                    error_cnt += 1
                    results.append((status, bel, msg))
                else:
                    success_cnt += 1

    print(f"Total: {cnt}  Success: {success_cnt}  Errors: {error_cnt}")
    with open('test_results.json', 'w') as f:
        json.dump(results, f, indent=4)


def main():
    run_examples()


if __name__ == '__main__':
    main()

