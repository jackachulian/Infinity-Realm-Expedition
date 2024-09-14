cases = []
point_heights = []
mirrored_point_heights = []

for a in range(4):
    for b in range(4):
        for c in range(4):
            for d in range(4):
                heights = [a, b, c, d]

                sorted_heights = [a, b, c, d]
                sorted_heights.sort()

                valid = True

                for i in range(len(sorted_heights)-1):
                    if sorted_heights[i+1] - sorted_heights[i] > 1:
                        valid = False
                        break
                
                if not valid:
                    continue

                higher_clockwise = [a > b, b > d, d > c, c > a]
                lower_clockwise = [a < b, b < d, d < c, c < a]

                case = [0, 0, 0, 0, 0, 0]

                for i in range(4):
                    if higher_clockwise[i]:
                        case[i] = 1 # 1 means higher clockwise
                    elif lower_clockwise[i]:
                        case[i] = 2 # 2 means lower clockwise

                if a > d:
                    case[4] = 1
                elif a < d:
                    case[4] = 2
                if b > c:
                    case[5] = 1
                elif b < c:
                    case[5] = 2


                case2 = [case[3], case[0], case[1], case[2], case[5], case[4]]
                case3 = [case[2], case[3], case[0], case[1], case[4], case[5]]
                case4 = [case[1], case[2], case[3], case[0], case[5], case[4]]

                if not (case in cases or case2 in cases or case3 in cases or case4 in cases):
                    cases.append(case)
                    point_heights.append(heights)
                    print(">", heights)
                else:
                    print(heights, "duplicate case")

for i, case in enumerate(cases):
    print("case", i)
    print(case)
    print("heights:", point_heights[i])
    print()