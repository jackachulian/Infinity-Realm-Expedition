cases = []

for ab in range(3):
    for bd in range(3):
        for cd in range(3):
            for ad in range(3):
                case = (ab, bd, cd, ad)
                case2 = (bd, cd, ad, ab)
                case3 = (cd, ad, ab, bd)
                case4 = (ad, ab, bd, cd)

                if not (case in cases or case2 in cases or case3 in cases or case4 in cases):
                    cases.append(case)

for i, case in enumerate(cases):
    print(i,"=",case)